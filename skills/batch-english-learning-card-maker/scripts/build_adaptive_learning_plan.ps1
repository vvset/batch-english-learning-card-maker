param(
  [Parameter(Mandatory = $true)]
  [string]$PackDir,

  [int]$Age = 7,
  [int]$DailyMinutes = 15,
  [int]$Days = 7,
  [int]$NewItemsPerDay = 0,
  [string]$LearningRecordPath = '',
  [switch]$StrictContent
)

$ErrorActionPreference = 'Stop'

function Test-HasChinese {
  param([string]$Text)
  return "$Text" -match '[\u4e00-\u9fff]'
}

function Get-WordCount {
  param([string]$Text)
  return @([regex]::Matches("$Text", "[A-Za-z]+(?:'[A-Za-z]+)?")).Count
}

function Get-StatusInfo {
  param([string]$Status)
  $normalized = "$Status".Trim()
  if (-not $normalized -or $normalized -match '未学\s*/\s*半会\s*/\s*已会') {
    return [pscustomobject]@{ rank = 0; label = '未学习'; interval = 0 }
  }
  if ($normalized -match '^(已会|已掌握|mastered)$') {
    return [pscustomobject]@{ rank = 3; label = '已掌握'; interval = 7 }
  }
  if ($normalized -match '^(半会|易忘|学习中|learning|review)$') {
    return [pscustomobject]@{ rank = 1; label = '需要复习'; interval = 1 }
  }
  return [pscustomobject]@{ rank = 0; label = '未学习'; interval = 0 }
}

function Get-RecommendedNewCount {
  param([int]$LearnerAge, [int]$Minutes)
  $base = if ($LearnerAge -le 5) { 3 } elseif ($LearnerAge -le 7) { 5 } elseif ($LearnerAge -le 9) { 7 } else { 9 }
  $timeLimit = [Math]::Max(2, [Math]::Floor($Minutes / 2.5))
  return [Math]::Min($base, $timeLimit)
}

function Get-MaxSentenceWords {
  param([int]$LearnerAge)
  if ($LearnerAge -le 5) { return 5 }
  if ($LearnerAge -le 7) { return 8 }
  if ($LearnerAge -le 9) { return 12 }
  return 16
}

$resolvedPackDir = (Resolve-Path -LiteralPath $PackDir).Path
$manifestPath = Join-Path $resolvedPackDir 'manifest.csv'
if (-not (Test-Path -LiteralPath $manifestPath)) {
  throw "找不到 manifest.csv：$manifestPath"
}

$manifest = @(Import-Csv -LiteralPath $manifestPath -Encoding UTF8)
if ($manifest.Count -eq 0) {
  throw 'manifest.csv 没有可用内容。'
}

if (-not $LearningRecordPath) {
  $candidate = Join-Path $resolvedPackDir 'learning-record.csv'
  if (Test-Path -LiteralPath $candidate) { $LearningRecordPath = $candidate }
}

$recordLookup = @{}
if ($LearningRecordPath -and (Test-Path -LiteralPath $LearningRecordPath)) {
  foreach ($record in @(Import-Csv -LiteralPath $LearningRecordPath -Encoding UTF8)) {
    $key = if ($record.card) { "$($record.card)".ToLowerInvariant() } else { "$($record.english)".ToLowerInvariant() }
    $recordLookup[$key] = $record
  }
}

$maxSentenceWords = Get-MaxSentenceWords $Age
$auditRows = New-Object System.Collections.Generic.List[object]
foreach ($item in $manifest) {
  $issues = New-Object System.Collections.Generic.List[string]
  $warnings = New-Object System.Collections.Generic.List[string]
  $english = "$($item.english)".Trim()
  $phonetic = "$($item.phonetic)".Trim()
  $meaning = "$($item.meaning)".Trim()
  $wordCount = Get-WordCount $english

  if (-not $english) { $issues.Add('缺少英文或学习页标题') }
  elseif ($item.type -ne 'lesson' -and $english -notmatch '[A-Za-z]') { $issues.Add('英文内容不包含英文字母') }
  if (-not $phonetic) { $issues.Add('缺少音标') }
  elseif ($phonetic -notmatch '^/.+/$') { $warnings.Add('音标未使用 /.../ 格式') }
  if (-not $meaning) { $issues.Add('缺少中文意思或学习页内容摘要') }
  elseif ($item.type -ne 'lesson' -and -not (Test-HasChinese $meaning)) { $warnings.Add('中文意思中未检测到中文') }

  if ($item.type -in @('word','combo') -and $item.visual_source -notin @('exact-asset','reliable-built-in')) {
    $issues.Add("配图来源不可直接用于正式学习：$($item.visual_source)")
  }
  if ($item.phonetic_source -match 'generated') {
    $warnings.Add("音标来源需要人工确认：$($item.phonetic_source)")
  }
  if ($item.type -in @('sentence','combo') -and $wordCount -gt $maxSentenceWords) {
    $warnings.Add("句子包含 $wordCount 个英文词，可能超过 $Age 岁建议长度 $maxSentenceWords")
  }
  if ($item.type -eq 'word' -and $english -match '\s') {
    $warnings.Add('单词卡中检测到多个英文词')
  }

  $status = if ($issues.Count -gt 0) { 'blocked' } elseif ($warnings.Count -gt 0) { 'review' } else { 'pass' }
  $auditRows.Add([pscustomobject]@{
    status = $status
    type = $item.type
    english = $english
    phonetic = $phonetic
    meaning = $meaning
    word_count = $wordCount
    file = Split-Path "$($item.file)" -Leaf
    issues = $issues -join '；'
    warnings = $warnings -join '；'
  })
}

$duplicateGroups = @($manifest |
  Where-Object { $_.type -ne 'lesson' } |
  Group-Object { "$($_.type)|$("$($_.english)".Trim().ToLowerInvariant())" } |
  Where-Object { $_.Count -gt 1 })
foreach ($group in $duplicateGroups) {
  $sample = $group.Group[0]
  $auditRows.Add([pscustomobject]@{
    status = 'review'
    type = $sample.type
    english = $sample.english
    phonetic = ''
    meaning = $sample.meaning
    word_count = 0
    file = ''
    issues = ''
    warnings = "同类型英文重复 $($group.Count) 次"
  })
}

$auditPath = Join-Path $resolvedPackDir 'content-audit.csv'
$auditRows | Export-Csv -LiteralPath $auditPath -NoTypeInformation -Encoding UTF8

$today = (Get-Date).Date
$reviewQueue = New-Object System.Collections.Generic.List[object]
$newQueue = New-Object System.Collections.Generic.List[object]
foreach ($item in $manifest) {
  if ($item.type -eq 'lesson') { continue }
  $card = Split-Path "$($item.file)" -Leaf
  $key = $card.ToLowerInvariant()
  $record = if ($recordLookup.ContainsKey($key)) { $recordLookup[$key] } elseif ($recordLookup.ContainsKey("$($item.english)".ToLowerInvariant())) { $recordLookup["$($item.english)".ToLowerInvariant()] } else { $null }
  $statusInfo = Get-StatusInfo $(if ($record) { $record.status } else { '' })
  $reviewDate = $null
  if ($record -and $record.review_date) {
    [datetime]$parsed = [datetime]::MinValue
    if ([datetime]::TryParse("$($record.review_date)", [ref]$parsed)) { $reviewDate = $parsed.Date }
  }

  $entry = [pscustomobject]@{
    card = $card
    type = $item.type
    english = $item.english
    meaning = $item.meaning
    current_status = $statusInfo.label
    priority = if ($statusInfo.rank -eq 1) { 1 } elseif ($reviewDate -and $reviewDate -le $today) { 2 } elseif ($statusInfo.rank -eq 0) { 3 } else { 4 }
    next_review_date = if ($statusInfo.interval -gt 0) { $today.AddDays($statusInfo.interval).ToString('yyyy-MM-dd') } else { $today.ToString('yyyy-MM-dd') }
    reason = if ($statusInfo.rank -eq 1) { '尚未完全掌握，优先复习' } elseif ($reviewDate -and $reviewDate -le $today) { '已到复习日期' } elseif ($statusInfo.rank -eq 0) { '尚未学习' } else { '已掌握，低频复习' }
  }

  if ($statusInfo.rank -eq 0) { $newQueue.Add($entry) }
  else { $reviewQueue.Add($entry) }
}

$reviewQueue = @($reviewQueue | Sort-Object priority, english)
$dueReviewQueue = @($reviewQueue | Where-Object { $_.priority -le 2 })
$newQueue = @($newQueue | Sort-Object type, english)
$reviewQueuePath = Join-Path $resolvedPackDir 'review-queue.csv'
$reviewQueue | Export-Csv -LiteralPath $reviewQueuePath -NoTypeInformation -Encoding UTF8

if ($NewItemsPerDay -le 0) { $NewItemsPerDay = Get-RecommendedNewCount $Age $DailyMinutes }
$maxDailyItems = [Math]::Max($NewItemsPerDay + 2, [Math]::Floor($DailyMinutes / 1.5))
$planRows = New-Object System.Collections.Generic.List[object]
$newIndex = 0
$reviewIndex = 0
$scheduledReviews = @{}

for ($day = 1; $day -le $Days; $day++) {
  $date = $today.AddDays($day - 1).ToString('yyyy-MM-dd')
  $daily = New-Object System.Collections.Generic.List[object]
  $dailyCards = New-Object System.Collections.Generic.HashSet[string]

  if ($scheduledReviews.ContainsKey($day)) {
    foreach ($entry in $scheduledReviews[$day]) {
      if ($dailyCards.Add($entry.card)) { $daily.Add($entry) }
    }
  }

  $reviewTarget = [Math]::Min([Math]::Max(2, [Math]::Floor($maxDailyItems * 0.4)), $dueReviewQueue.Count)
  for ($i = 0; $i -lt $reviewTarget -and $dueReviewQueue.Count -gt 0 -and $daily.Count -lt $maxDailyItems; $i++) {
    $entry = $dueReviewQueue[$reviewIndex % $dueReviewQueue.Count]
    if ($dailyCards.Add($entry.card)) { $daily.Add($entry) }
    $reviewIndex++
  }

  for ($i = 0; $i -lt $NewItemsPerDay -and $newIndex -lt $newQueue.Count -and $daily.Count -lt $maxDailyItems; $i++) {
    $entry = $newQueue[$newIndex]
    if ($dailyCards.Add($entry.card)) { $daily.Add($entry) }
    $newIndex++
    foreach ($offset in @(1, 3)) {
      $reviewDay = $day + $offset
      if ($reviewDay -le $Days) {
        if (-not $scheduledReviews.ContainsKey($reviewDay)) {
          $scheduledReviews[$reviewDay] = New-Object System.Collections.Generic.List[object]
        }
        $scheduledReviews[$reviewDay].Add([pscustomobject]@{
          card = $entry.card
          type = $entry.type
          english = $entry.english
          meaning = $entry.meaning
          current_status = '需要复习'
          priority = 1
          next_review_date = $today.AddDays($reviewDay - 1).ToString('yyyy-MM-dd')
          reason = "新学后第 $offset 天间隔复习"
        })
      }
    }
  }

  $position = 0
  foreach ($entry in $daily) {
    $position++
    $planRows.Add([pscustomobject]@{
      day = $day
      date = $date
      order = $position
      action = if ($entry.current_status -eq '未学习') { '学习新内容' } else { '复习巩固' }
      card = $entry.card
      type = $entry.type
      english = $entry.english
      meaning = $entry.meaning
      parent_prompt = if ($entry.type -eq 'word') { '先看图说中文，再说英文，最后跟读3遍。' } else { '先听家长读，再让孩子独立说一遍。' }
      next_review_date = $entry.next_review_date
    })
  }
}

$planPath = Join-Path $resolvedPackDir 'personalized-learning-plan.csv'
$planRows | Export-Csv -LiteralPath $planPath -NoTypeInformation -Encoding UTF8

$blockedCount = @($auditRows | Where-Object { $_.status -eq 'blocked' }).Count
$reviewCount = @($auditRows | Where-Object { $_.status -eq 'review' }).Count
$passCount = @($auditRows | Where-Object { $_.status -eq 'pass' }).Count
$summaryPath = Join-Path $resolvedPackDir 'learner-summary.txt'
@"
个性化学习包摘要

孩子年龄：$Age 岁
每日时长：$DailyMinutes 分钟
计划天数：$Days 天
每日建议新内容：$NewItemsPerDay 条
计划条目：$($planRows.Count) 条
待复习内容：$($reviewQueue.Count) 条
尚未学习内容：$($newQueue.Count) 条

内容审计：
- 通过：$passCount
- 建议复核：$reviewCount
- 阻止正式使用：$blockedCount

使用方法：
1. 先查看 content-audit.csv，处理 blocked 项。
2. 每天按 personalized-learning-plan.csv 的顺序学习。
3. 在 learning-record.csv 中把状态改成“未学”“半会”或“已会”，并填写 review_date。
4. 再次运行本脚本，会根据最新掌握情况重新安排复习。
"@ | Set-Content -LiteralPath $summaryPath -Encoding UTF8

Write-Output "Content audit: $auditPath"
Write-Output "Review queue: $reviewQueuePath"
Write-Output "Personalized plan: $planPath"
Write-Output "Learner summary: $summaryPath"

if ($StrictContent -and $blockedCount -gt 0) {
  throw "内容审计发现 $blockedCount 条阻止项，请先修复 content-audit.csv 中的问题。"
}
