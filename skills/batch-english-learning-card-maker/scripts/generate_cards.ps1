#requires -Version 7.0

param(
  [ValidateSet('preschool-3-5','kindergarten-5-6','grade-1-6-7','grade-2-7-8','grade-3-8-9','primary-4-6-9-12')]
  [string]$Stage = 'grade-1-6-7',

  [ValidateSet('auto','domestic','international')]
  [string]$System = 'auto',

  [string]$Level = '',

  [ValidateSet('word','sentence','combo','lesson','mixed')]
  [string]$Mode = 'mixed',

  [int]$WordCount = 20,
  [int]$SentenceCount = 10,
  [int]$ComboCount = 10,
  [int]$LessonCount = 2,

  [string]$Title = '',
  [string]$Theme = 'general',
  [string]$OutputDir = '',
  [string]$BackgroundImage = '',
  [string]$AssetDir = '',
  [switch]$AutoCounts,
  [switch]$CoursePack,
  [switch]$ThemePack,
  [switch]$CompletePack,
  [switch]$FormalCompletePack,
  [switch]$PrintLayout,
  [switch]$PlanOnly,
  [switch]$RecommendThemesOnly,
  [switch]$SevenDayPack,
  [switch]$AssetCheckOnly,
  [switch]$StrictAssets,
  [switch]$AllowApproximateVisuals,
  [switch]$ActivityPack,
  [switch]$ActivityImages,
  [switch]$PhonicsPack,
  [switch]$LearningRecord,
  [switch]$ExportZip,
  [ValidateSet(
    '',
    'preschool-daily','preschool-animals','preschool-breakfast','preschool-family','preschool-bedtime',
    'kindergarten-animals','kindergarten-classroom','kindergarten-breakfast','kindergarten-family',
    'grade1-classroom','grade1-animals','grade1-breakfast','grade1-family','grade1-weather','grade1-park','grade1-cleaning',
    'grade2-classroom','grade2-animals','grade2-weather',
    'prea1-animals','prea1-daily'
  )]
  [string]$Preset = '',
  [ValidateSet('allow-generated','curated-only')]
  [string]$PhoneticPolicy = 'allow-generated',
  [switch]$StrictContent,
  [ValidateSet('4','6')]
  [string]$CardsPerPrintPage = '4',
  [ValidateSet('auto','icon','storybook','watercolor')]
  [string]$VisualStyle = 'auto',
  [ValidateSet('auto','starter','basic','challenge')]
  [string]$DifficultyMode = 'auto'
)

$ErrorActionPreference = 'Stop'
$SkillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$Refs = Join-Path $SkillRoot 'references'
$WordBankPath = Join-Path $Refs 'graded-word-bank-100.md'
$SentenceBankPath = Join-Path $Refs 'graded-library.md'
$ThemePackPath = Join-Path $Refs 'theme-lesson-packs.md'
if (-not $AssetDir) { $AssetDir = Join-Path $SkillRoot 'assets\illustrations' }
$VerifiedAssetDir = Join-Path $SkillRoot 'assets\illustrations'
$VerifiedAssetRegistryPath = Join-Path $Refs 'verified-asset-registry.csv'

if (-not $OutputDir) {
  $OutputDir = Join-Path (Get-Location) 'output\english-learning-cards'
}
New-Item -ItemType Directory -Force $OutputDir | Out-Null

Add-Type -AssemblyName System.Drawing

$script:VisualStyle = if ($VisualStyle -eq 'auto') { 'storybook' } else { $VisualStyle }
$script:VerifiedAssetRegistry = @{}
if (Test-Path -LiteralPath $VerifiedAssetRegistryPath) {
  foreach ($record in (Import-Csv -LiteralPath $VerifiedAssetRegistryPath -Encoding UTF8)) {
    $script:VerifiedAssetRegistry[$record.english.ToLowerInvariant()] = $record
  }
}

function Get-RowsFromMarkdownCsv {
  param(
    [string]$Path,
    [string]$Header,
    [string]$Prefix
  )
  $lines = Get-Content -LiteralPath $Path -Encoding UTF8 | Where-Object { $_ -match "^$([regex]::Escape($Prefix))," }
  if (-not $lines) { return @() }
  return @($lines | ConvertFrom-Csv -Header ($Header -split ','))
}

function Sanitize-Name {
  param([string]$Text)
  $value = $Text.ToLowerInvariant() -replace '[^a-z0-9]+','-'
  $value = $value.Trim('-')
  if (-not $value) { $value = 'card' }
  return $value
}

function Escape-Html {
  param([string]$Text)
  if ($null -eq $Text) { return '' }
  return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Convert-StatusLabel {
  param([string]$Value)
  $map = @{
    'pass' = '通过'
    'pass-with-visual-check' = '通过（建议复查配图）'
    'needs-check' = '需要检查'
    'fulfilled' = '已完成'
    'reduced-no-repeat' = '已减少（不重复凑数）'
    'over-generated' = '超出请求数量'
    'ready' = '就绪'
    'reduced' = '已减少'
    'info' = '信息'
    'missing' = '缺失'
    'safe' = '安全'
    'needs-review' = '需要复查'
    'will-exclude' = '将排除'
    'excluded-missing-visual' = '已排除：缺少配图'
    'needs-asset' = '缺少素材'
    'needs-verification' = '需要审核素材'
    'needs-edge-review' = '截断风险需复查'
    'duplicate' = '重复'
    'unregistered' = '未登记'
    'not-approved' = '未审核通过'
    'filename-mismatch' = '文件名不匹配'
    'hash-mismatch' = '文件指纹不匹配'
  }
  if ($map.ContainsKey($Value)) { return $map[$Value] }
  return $Value
}

function Convert-TypeLabel {
  param([string]$Value)
  $map = @{
    'word' = '单词卡'
    'sentence' = '短句卡'
    'combo' = '单词+短句卡'
    'lesson' = '多句学习页'
    'mixed' = '混合模式'
    'activity' = '互动练习'
  }
  if ($map.ContainsKey($Value)) { return $map[$Value] }
  return $Value
}

function Convert-FieldLabel {
  param([string]$Value)
  $map = @{
    'file' = '文件'
    'type' = '类型'
    'card_type' = '卡片类型'
    'skill' = '卡片类型'
    'system' = '体系'
    'level' = '等级'
    'stage' = '年龄/年级阶段'
    'theme' = '主题'
    'difficulty' = '难度'
    'source' = '内容来源'
    'phonetic_source' = '音标来源'
    'english' = '英文'
    'phonetic' = '音标'
    'meaning' = '中文意思'
    'example' = '例句'
    'example_meaning' = '例句中文'
    'visual_cue' = '应显示画面'
    'visual_source' = '配图来源'
    'expected_visual' = '应显示画面'
    'asset' = '素材文件'
    'verification' = '素材审核'
    'category' = '素材分类'
    'required_filename' = '建议文件名'
    'required_asset' = '需要补充素材'
    'asset_prompt' = '素材提示词'
    'width' = '宽度'
    'height' = '高度'
    'edge_hits' = '贴边检测点'
    'edge_status' = '边缘状态'
    'generation_status' = '生成处理'
    'dimensions' = '图片尺寸'
    'grade' = '质量等级'
    'layout_score' = '排版分'
    'readability' = '可读性'
    'status' = '状态'
    'issues' = '问题'
    'metric' = '检查项'
    'requested' = '请求数量'
    'available' = '可用数量'
    'generated' = '生成数量'
    'note' = '说明'
    'count' = '数量'
    'files' = '文件列表'
    'activity' = '练习'
    'prompt' = '题目'
    'answer' = '答案'
    'options' = '选项'
    'parent_tip' = '家长提示'
    'word' = '单词'
    'first_letter' = '首字母'
    'phonics_focus' = '自然拼读重点'
    'practice' = '练习方式'
    'date' = '日期'
    'card' = '卡片'
    'review_date' = '复习日期'
    'parent_note' = '家长备注'
    'order' = '顺序'
    'day' = '第几天'
    'step' = '学习步骤'
    'focus' = '学习重点'
    'cards' = '使用卡片'
    'action' = '怎么带读'
    'parent_question' = '家长提问'
    'review' = '复习方式'
    'item' = '项目'
    'value' = '值'
    'gap_type' = '缺口类型'
    'priority' = '优先级'
    'problem' = '问题'
    'suggested_action' = '建议动作'
    'target' = '对象'
  }
  if ($map.ContainsKey($Value)) { return $map[$Value] }
  return $Value
}

function Convert-UserValue {
  param([string]$Name, $Value)
  if ($null -eq $Value) { return $Value }
  if ($Value -isnot [string]) { return $Value }
  if ($Name -match '(^status$|_status$)') { return Convert-StatusLabel $Value }
  if ($Name -in @('type','card_type','skill')) { return Convert-TypeLabel $Value }
  $map = @{
    'domestic' = '国内体系'
    'international' = '国际体系'
    'auto' = '自动'
    'starter' = '启蒙'
    'basic' = '基础'
    'challenge' = '进阶'
    'easy' = '简单'
    'medium' = '中等'
    'upper-primary' = '小学高年级'
    'domestic-preschool' = '国内幼儿启蒙'
    'domestic-grade-1-2' = '国内小学一二年级'
    'domestic-grade-3-4' = '国内小学三四年级'
    'domestic-grade-5-6' = '国内小学五六年级'
    'pre-a1' = 'Pre-A1 启蒙'
    'a1' = 'A1 基础'
    'a2' = 'A2 进阶'
    'preschool-3-5' = '3-5岁 / 幼儿园'
    'kindergarten-5-6' = '5-6岁 / 学前班'
    'grade-1-6-7' = '6-7岁 / 一年级'
    'grade-2-7-8' = '7-8岁 / 二年级'
    'grade-3-8-9' = '8-9岁 / 三年级'
    'primary-4-6-9-12' = '9-12岁 / 小学高年级'
    'cleaning-room' = '打扫房间'
    'classroom' = '教室课堂'
    'zoo-animals' = '动物园'
    'breakfast' = '早餐'
    'bedtime' = '睡前'
    'weather' = '天气'
    'park-play' = '公园玩耍'
    'family' = '家庭'
    'curated-bank' = '已整理内容库'
    'curated-word' = '已整理单词'
    'generated-template' = '模板生成'
    'mixed-with-generated' = '已整理+模板生成'
    'stage-bank' = '阶段内容库'
    'theme-pack' = '主题内容库'
    'theme-pack+stage-bank' = '主题库+阶段库'
    'stage-bank+generated' = '阶段库+补充生成'
    'not-required' = '不需要配图'
    'exact-asset' = '固定素材'
    'reliable-built-in' = '内置可靠简图'
    'approximate-built-in' = '近似简图'
    'verified' = '已审核'
    'unregistered' = '未登记'
    'animals' = '动物'
    'food' = '食物'
    'school' = '学校/文具'
    'nature' = '自然'
    'people' = '人物'
    'object' = '物品'
    'general' = '通用'
  }
  if ($map.ContainsKey($Value)) { return $map[$Value] }
  return $Value
}

function Export-CsvForExcel {
  param(
    [Parameter(ValueFromPipeline = $true)]
    [object]$InputObject,
    [string]$Path
  )
  begin { $rows = New-Object System.Collections.Generic.List[object] }
  process {
    if ($null -ne $InputObject) { $rows.Add($InputObject) }
  }
  end {
    $localizedRows = @($rows | ForEach-Object {
      $source = $_
      $out = [ordered]@{}
      foreach ($property in $source.PSObject.Properties) {
        $value = Convert-UserValue $property.Name $property.Value
        $out[(Convert-FieldLabel $property.Name)] = $value
      }
      [pscustomobject]$out
    })
    $localizedRows | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding UTF8BOM
  }
}

function Write-AssetPromptPack {
  param(
    [object[]]$Rows,
    [string]$Path
  )
  if (-not $Rows -or $Rows.Count -eq 0) { return }
  $blocks = @($Rows | ForEach-Object {
    @"
文件名：$($_.required_filename)
英文：$($_.english)
中文：$($_.meaning)
分类：$($_.category)
应显示：$($_.expected_visual)
保存位置：assets/illustrations/$($_.required_filename)

可复制给绘图工具的提示词：
$($_.asset_prompt)
"@
  })
  Set-Content -LiteralPath $Path -Value ($blocks -join "`r`n---`r`n") -Encoding UTF8
}

function Write-TableHtml {
  param(
    [object[]]$Rows,
    [string[]]$Columns,
    [hashtable]$Labels,
    [string]$Title,
    [string]$Path
  )
  $head = ($Columns | ForEach-Object { "<th>$(Escape-Html $Labels[$_])</th>" }) -join ''
  $body = ($Rows | ForEach-Object {
    $row = $_
    $cells = ($Columns | ForEach-Object { "<td>$(Escape-Html $row.$_)</td>" }) -join ''
    "<tr>$cells</tr>"
  }) -join "`n"
  $html = @"
<!doctype html>
<meta charset="utf-8">
<title>$(Escape-Html $Title)</title>
<style>
body{margin:0;padding:28px;font-family:Segoe UI,Microsoft YaHei,sans-serif;background:#fff8ec;color:#26364a}
h1{font-size:28px;margin:0 0 18px;color:#1f5d68}
table{width:100%;border-collapse:collapse;background:white;border-radius:12px;overflow:hidden;box-shadow:0 2px 14px rgba(0,0,0,.08)}
th,td{border-bottom:1px solid #f1e4d2;padding:12px 14px;text-align:left;vertical-align:top;font-size:15px;line-height:1.55}
th{background:#eaf7ff;color:#1f5d68;font-weight:700}
tr:last-child td{border-bottom:0}
@media print{body{background:white;padding:0}table{box-shadow:none}th,td{font-size:11pt}}
</style>
<h1>$(Escape-Html $Title)</h1>
<table><thead><tr>$head</tr></thead><tbody>$body</tbody></table>
"@
  Set-Content -LiteralPath $Path -Value $html -Encoding UTF8
}

function Normalize-Theme {
  param([string]$Value)
  $map = @{
    '打扫房间' = 'cleaning-room'
    '打扫' = 'cleaning-room'
    '清洁' = 'cleaning-room'
    '教室' = 'classroom'
    '课堂' = 'classroom'
    '学校' = 'classroom'
    '动物园' = 'zoo-animals'
    '动物' = 'zoo-animals'
    '早餐' = 'breakfast'
    '睡前' = 'bedtime'
    '晚安' = 'bedtime'
    '天气' = 'weather'
    '公园' = 'park-play'
    '玩耍' = 'park-play'
    '家庭' = 'family'
    '家人' = 'family'
  }
  if ($map.ContainsKey($Value)) { return $map[$Value] }
  return ($Value.ToLowerInvariant() -replace '[^a-z0-9]+','-').Trim('-')
}

function Get-ThemeDisplayName {
  param([string]$Value)
  $map = @{
    'cleaning-room' = '打扫房间'
    'classroom' = '教室课堂'
    'zoo-animals' = '动物园'
    'breakfast' = '早餐'
    'bedtime' = '睡前'
    'weather' = '天气'
    'park-play' = '公园玩耍'
    'family' = '家庭'
    'general' = '英语练习'
  }
  if ($map.ContainsKey($Value)) { return $map[$Value] }
  return $Value
}

function Get-RecommendedThemes {
  param([string]$CurrentStage)
  $themes = @{
    'preschool-3-5' = @(
      @('zoo-animals','动物','先看图认动物，最容易吸引低龄儿童'),
      @('breakfast','食物','适合日常亲子对话'),
      @('family','家庭','贴近孩子生活'),
      @('weather','天气','每天都能复习'),
      @('park-play','公园玩耍','动作和场景更直观')
    )
    'kindergarten-5-6' = @(
      @('zoo-animals','动物','适合单词和简单句'),
      @('classroom','教室课堂','提前熟悉学前/小学场景'),
      @('breakfast','食物','便于家长每天带读'),
      @('family','家庭','句子简单自然'),
      @('bedtime','睡前','适合晚间短句')
    )
    'grade-1-6-7' = @(
      @('classroom','教室课堂','最贴近一年级学习'),
      @('zoo-animals','动物','适合单词+短句组合'),
      @('breakfast','食物','适合口语练习'),
      @('weather','天气','适合每日问答'),
      @('family','家庭','适合亲子带读')
    )
    'grade-2-7-8' = @(
      @('classroom','教室课堂','适合课堂指令和问答'),
      @('weather','天气','适合句型扩展'),
      @('park-play','公园玩耍','适合动作句'),
      @('family','家庭','适合描述和问答'),
      @('breakfast','食物','适合日常表达')
    )
    'grade-3-8-9' = @(
      @('weather','天气','适合主题表达'),
      @('park-play','公园玩耍','适合多句学习页'),
      @('classroom','教室课堂','适合复习和对话'),
      @('family','家庭','适合描述人物'),
      @('bedtime','睡前','适合日常流程表达')
    )
    'primary-4-6-9-12' = @(
      @('weather','天气','适合阅读式句子'),
      @('family','家庭','适合描述和理由'),
      @('park-play','公园玩耍','适合场景短文'),
      @('classroom','教室课堂','适合学习策略表达'),
      @('breakfast','食物','适合健康和生活主题')
    )
  }
  $selected = if ($themes.ContainsKey($CurrentStage)) { $themes[$CurrentStage] } else { $themes['grade-1-6-7'] }
  $rank = 1
  return @($selected | ForEach-Object {
    [pscustomobject]@{
      rank = $rank++
      theme = $_[0]
      display_name = $_[1]
      reason = $_[2]
    }
  })
}

function Get-ExpectedVisualCue {
  param([string]$English, [string]$Meaning)
  $key = Normalize-LevelKey $English
  $exact = @{
    'cat' = '小猫，必须有猫耳、胡须、尾巴'
    'dog' = '小狗，必须有狗鼻口、狗耳、尾巴'
    'rabbit' = '兔子，必须有长耳朵'
    'animal' = '多种动物或动物脚印'
    'pet' = '家养宠物，例如猫和狗'
    'mouse' = '小老鼠，必须有圆耳朵和细尾巴'
    'frog' = '青蛙，必须有绿色身体和突出眼睛'
    'book' = '打开或合上的书本'
    'pencil' = '铅笔'
    'pen' = '钢笔或水笔'
    'bag' = '书包'
    'apple' = '苹果'
    'banana' = '香蕉'
    'orange' = '橙子或橘子'
    'sun' = '太阳'
    'moon' = '月亮'
    'star' = '星星'
    'cloud' = '云朵'
    'rain' = '下雨或雨滴'
    'tree' = '树'
    'flower' = '花'
    'ball' = '球'
    'chair' = '椅子'
    'desk' = '课桌'
    'door' = '门'
    'window' = '窗户'
  }
  if ($exact.ContainsKey($key)) { return $exact[$key] }
  if ($key -match 'cat|dog|rabbit|panda|monkey|bird|fish|duck|cow|pig|sheep|horse|bear|lion|tiger|elephant|giraffe|zebra|turtle|mouse|frog|snake|fox|wolf|deer|goat|hen') { return "对应动物：$Meaning" }
  if ($key -match 'book|notebook|story|page|letter|word|library|paper|map|board') { return "学习用品或书本：$Meaning" }
  if ($key -match 'pencil|pen|crayon|ruler|eraser|marker|glue') { return "文具：$Meaning" }
  if ($key -match 'apple|banana|pear|grape|peach|melon|lemon|strawberry|watermelon|pineapple|bread|cake|rice|noodles|cookie|milk|water|egg|soup|chicken|juice|carrot|potato|tomato|corn|cheese') { return "食物或饮品：$Meaning" }
  if ($key -match 'sun|moon|cloud|rain|weather|star|sky|wind|snow|rainbow|season') { return "天气或天空元素：$Meaning" }
  if ($key -match 'chair|table|desk|door|window|clock|home|room|bed|sofa|lamp|house') { return "家居或教室物品：$Meaning" }
  if ($key -match 'car|train|bus|taxi|plane|boat|subway|bicycle') { return "交通工具：$Meaning" }
  if ($key -match 'tree|flower|leaf|grass|garden|park|forest|mountain|river|lake|beach') { return "自然场景：$Meaning" }
  if ($key -match 'mom|dad|baby|friend|teacher|family|mother|father|sister|brother|grandma|grandpa|child') { return "人物或家庭关系：$Meaning" }
  return "清晰表达中文意思：$Meaning"
}

function Resolve-IllustrationAsset {
  param([string]$English)
  $safe = Sanitize-Name $English
  foreach ($dir in @($VerifiedAssetDir, $AssetDir)) {
    foreach ($ext in @('png','jpg','jpeg','webp')) {
      $candidate = Join-Path $dir "$safe.$ext"
      if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
  }
  return ''
}

function Get-AssetVerificationStatus {
  param([string]$English, [string]$AssetPath = '')
  if (-not $AssetPath) { $AssetPath = Resolve-IllustrationAsset $English }
  if (-not $AssetPath) { return 'missing' }
  $key = (Sanitize-Name $English).ToLowerInvariant()
  if (-not $script:VerifiedAssetRegistry.ContainsKey($key)) { return 'unregistered' }
  $record = $script:VerifiedAssetRegistry[$key]
  if ($record.review_status -ne 'approved') { return 'not-approved' }
  if ((Split-Path $AssetPath -Leaf).ToLowerInvariant() -ne $record.filename.ToLowerInvariant()) { return 'filename-mismatch' }
  $hash = (Get-FileHash -LiteralPath $AssetPath -Algorithm SHA256).Hash
  if ($hash -ne $record.sha256) { return 'hash-mismatch' }
  return 'verified'
}

function Get-AssetSafety {
  param([string]$AssetPath)
  if (-not $AssetPath -or -not (Test-Path -LiteralPath $AssetPath)) {
    return [pscustomobject]@{ status = 'missing'; width = 0; height = 0; edge_hits = 0; note = '缺少素材' }
  }
  $img = [System.Drawing.Bitmap]::new($AssetPath)
  try {
    $edgeHits = 0
    $margin = [Math]::Max(12, [Math]::Floor([Math]::Min($img.Width, $img.Height) * 0.02))
    $xs = @(0, $margin, ($img.Width - 1 - $margin), ($img.Width - 1))
    $ys = @(0, $margin, ($img.Height - 1 - $margin), ($img.Height - 1))
    $step = [Math]::Max(4, [Math]::Floor([Math]::Min($img.Width, $img.Height) / 180))
    foreach ($x in $xs) {
      for ($y = 0; $y -lt $img.Height; $y += $step) {
        $c = $img.GetPixel($x, $y)
        if ($c.A -gt 20 -and ($c.R -lt 238 -or $c.G -lt 238 -or $c.B -lt 238)) { $edgeHits += 1 }
      }
    }
    foreach ($y in $ys) {
      for ($x = 0; $x -lt $img.Width; $x += $step) {
        $c = $img.GetPixel($x, $y)
        if ($c.A -gt 20 -and ($c.R -lt 238 -or $c.G -lt 238 -or $c.B -lt 238)) { $edgeHits += 1 }
      }
    }
    $status = if ($edgeHits -eq 0) { 'safe' } else { 'needs-review' }
    $note = if ($edgeHits -eq 0) { '主体与边缘保留安全距离' } else { '素材在边缘安全区检测到内容，可能贴边或截断' }
    return [pscustomobject]@{ status = $status; width = $img.Width; height = $img.Height; edge_hits = $edgeHits; note = $note }
  } finally {
    $img.Dispose()
  }
}

function Get-AssetCategory {
  param([string]$English)
  $key = Sanitize-Name $English
  if ($key -match 'cat|dog|rabbit|panda|monkey|bird|fish|duck|cow|pig|sheep|horse|bear|lion|tiger|elephant|giraffe|zebra|turtle|mouse|frog|snake|fox|wolf|deer|goat|hen|animal|pet') { return 'animals' }
  if ($key -match 'book|pencil|pen|crayon|ruler|eraser|marker|glue|bag|backpack|desk|chair|door|window|teacher|school|classroom') { return 'classroom' }
  if ($key -match 'apple|banana|orange|pear|grape|bread|cake|rice|noodles|cookie|milk|water|egg|soup|chicken|juice|carrot|potato|tomato|corn|cheese|breakfast|lunch|dinner') { return 'food' }
  if ($key -match 'sun|moon|cloud|rain|weather|star|sky|wind|snow|rainbow|season|spring|summer|autumn|winter') { return 'weather' }
  if ($key -match 'mom|dad|baby|friend|family|mother|father|sister|brother|grandma|grandpa|child') { return 'family' }
  if ($key -match 'run|jump|walk|sing|dance|play|eat|drink|sleep|open|close|read|write|draw|listen|look|help|clean') { return 'actions' }
  return 'general'
}

function Get-AssetPrompt {
  param([string]$English, [string]$Meaning)
  $visual = Get-ExpectedVisualCue $English $Meaning
  return "儿童英语学习卡正式插画素材，主体是 $visual，单独主体，白色或透明感干净背景，儿童绘本水彩风，清晰可识别，适合3-8岁孩子观看，不要文字、不要字母、不要数字、不要水印。"
}

function Get-VisualSource {
  param([string]$English)
  $asset = Resolve-IllustrationAsset $English
  if ($asset) {
    if ((Get-AssetCategory $English) -eq 'animals' -and (Get-AssetVerificationStatus $English $asset) -ne 'verified') {
      return 'missing'
    }
    return 'exact-asset'
  }
  $key = Sanitize-Name $English
  $reliable = 'book|pencil|pen|crayon|bag|backpack|red|blue|yellow|green|pink|white|black|brown|purple|orange|sun|moon|cloud|rain|chair|bed|door|window|car|plane|boat|tree|flower|mountain|river|lake'
  if ($key -match "^($reliable)$") { return 'reliable-built-in' }
  if ($AllowApproximateVisuals) { return 'approximate-built-in' }
  return 'missing'
}

function Get-PhonicsFocus {
  param([string]$English)
  $key = Sanitize-Name $English
  $first = if ($key.Length -gt 0) { $key.Substring(0, 1) } else { '' }
  $map = @{
    'a' = '/æ/ or /eɪ/'
    'b' = '/b/'
    'c' = '/k/ or /s/'
    'd' = '/d/'
    'e' = '/e/ or /iː/'
    'f' = '/f/'
    'g' = '/ɡ/ or /dʒ/'
    'h' = '/h/'
    'i' = '/ɪ/ or /aɪ/'
    'j' = '/dʒ/'
    'k' = '/k/'
    'l' = '/l/'
    'm' = '/m/'
    'n' = '/n/'
    'o' = '/ɒ/ or /oʊ/'
    'p' = '/p/'
    'q' = '/kw/'
    'r' = '/r/'
    's' = '/s/'
    't' = '/t/'
    'u' = '/ʌ/ or /juː/'
    'v' = '/v/'
    'w' = '/w/'
    'x' = '/ks/'
    'y' = '/j/'
    'z' = '/z/'
  }
  if ($map.ContainsKey($first)) { return $map[$first] }
  return ''
}

function Get-ThemeWordPattern {
  param([string]$Value)
  $patterns = @{
    'classroom' = 'book|pencil|bag|desk|teacher|classroom|eraser|school|chair|door|window|notebook|marker|glue|paper|map|board|library|lesson|homework|ruler|pen|crayon'
    'zoo-animals' = 'animal|pet|cat|dog|bird|fish|duck|cow|pig|sheep|horse|rabbit|bear|lion|tiger|monkey|panda|mouse|frog|snake|fox|wolf|deer|goat|hen|elephant|giraffe|zebra|turtle'
    'breakfast' = 'breakfast|lunch|dinner|fruit|vegetable|apple|banana|pear|grape|bread|cake|rice|noodles|cookie|milk|water|egg|soup|chicken|juice|carrot|potato|tomato|corn|cheese'
    'bedtime' = 'bed|sleep|night|moon|star|room|lamp|home|tired|story|book|quiet'
    'weather' = 'weather|sun|moon|star|sky|cloud|rain|wind|snow|sunny|rainy|cloudy|windy|warm|cool|spring|summer|autumn|winter|storm|rainbow|temperature|season'
    'park-play' = 'park|play|run|jump|walk|tree|flower|leaf|grass|garden|kite|ball|toy|friend|ride|climb|throw|catch'
    'family' = 'family|mom|dad|baby|friend|mother|father|sister|brother|grandma|grandpa|child|home|room|house'
    'cleaning-room' = 'clean|dirty|wash|brush|room|floor|home|water|soap|bucket|rag|broom|help'
  }
  if ($patterns.ContainsKey($Value)) { return $patterns[$Value] }
  return ''
}

function Sort-RowsByTheme {
  param($Rows, [string]$ThemeValue)
  $pattern = Get-ThemeWordPattern $ThemeValue
  if (-not $pattern) { return @($Rows) }
  $matched = @($Rows | Where-Object { $_.english -match $pattern })
  $unmatched = @($Rows | Where-Object { $_.english -notmatch $pattern })
  return @($matched + $unmatched)
}

function Normalize-LevelKey {
  param([string]$Value)
  if (-not $Value) { return '' }
  return ($Value.ToLowerInvariant() -replace '\s+','-' -replace '_','-').Trim()
}

function Resolve-LearningLevel {
  param([string]$RequestedSystem, [string]$RequestedLevel, [string]$RequestedStage)
  $levelKey = Normalize-LevelKey $RequestedLevel
  $resolvedSystem = $RequestedSystem
  $resolvedLevel = if ($levelKey) { $levelKey } else { 'stage-only' }
  $resolvedStage = $RequestedStage

  $domesticMap = @{
    'domestic-preschool' = 'kindergarten-5-6'
    'preschool' = 'preschool-3-5'
    'kindergarten' = 'kindergarten-5-6'
    '幼儿' = 'preschool-3-5'
    '幼儿园' = 'preschool-3-5'
    '幼儿启蒙' = 'preschool-3-5'
    '学前班' = 'kindergarten-5-6'
    'domestic-grade-1-2' = 'grade-1-6-7'
    'grade-1-2' = 'grade-1-6-7'
    '一年级' = 'grade-1-6-7'
    '二年级' = 'grade-2-7-8'
    '一二年级' = 'grade-1-6-7'
    '小学低年级' = 'grade-1-6-7'
    'domestic-grade-3-4' = 'grade-3-8-9'
    'grade-3-4' = 'grade-3-8-9'
    '三年级' = 'grade-3-8-9'
    '四年级' = 'grade-3-8-9'
    '三四年级' = 'grade-3-8-9'
    '课标一级' = 'grade-3-8-9'
    'domestic-grade-5-6' = 'primary-4-6-9-12'
    'grade-5-6' = 'primary-4-6-9-12'
    '五年级' = 'primary-4-6-9-12'
    '六年级' = 'primary-4-6-9-12'
    '五六年级' = 'primary-4-6-9-12'
    '课标二级' = 'primary-4-6-9-12'
  }

  $internationalMap = @{
    'pre-a1' = 'grade-1-6-7'
    'prea1' = 'grade-1-6-7'
    'starters' = 'grade-1-6-7'
    'cambridge-starters' = 'grade-1-6-7'
    'a1' = 'grade-3-8-9'
    'movers' = 'grade-3-8-9'
    'cambridge-movers' = 'grade-3-8-9'
    'a2' = 'primary-4-6-9-12'
    'flyers' = 'primary-4-6-9-12'
    'cambridge-flyers' = 'primary-4-6-9-12'
  }

  if ($domesticMap.ContainsKey($RequestedLevel)) { $levelKey = $RequestedLevel }
  if ($internationalMap.ContainsKey($RequestedLevel)) { $levelKey = $RequestedLevel }

  if ($domesticMap.ContainsKey($levelKey)) {
    $resolvedSystem = 'domestic'
    $resolvedLevel = $levelKey
    $resolvedStage = $domesticMap[$levelKey]
  } elseif ($internationalMap.ContainsKey($levelKey)) {
    $resolvedSystem = 'international'
    $resolvedLevel = $levelKey
    $resolvedStage = $internationalMap[$levelKey]
  } elseif ($RequestedSystem -eq 'domestic' -and -not $RequestedLevel) {
    $resolvedLevel = switch ($RequestedStage) {
      'preschool-3-5' { 'domestic-preschool' }
      'kindergarten-5-6' { 'domestic-preschool' }
      'grade-1-6-7' { 'domestic-grade-1-2' }
      'grade-2-7-8' { 'domestic-grade-1-2' }
      'grade-3-8-9' { 'domestic-grade-3-4' }
      default { 'domestic-grade-5-6' }
    }
  } elseif ($RequestedSystem -eq 'international' -and -not $RequestedLevel) {
    $resolvedLevel = switch ($RequestedStage) {
      'preschool-3-5' { 'pre-a1' }
      'kindergarten-5-6' { 'pre-a1' }
      'grade-1-6-7' { 'pre-a1' }
      'grade-2-7-8' { 'a1' }
      'grade-3-8-9' { 'a1' }
      default { 'a2' }
    }
  }

  [pscustomobject]@{
    system = $resolvedSystem
    level = $resolvedLevel
    stage = $resolvedStage
  }
}

function Get-Difficulty {
  param([string]$Value)
  switch ($Value) {
    'preschool-3-5' { 'starter' }
    'kindergarten-5-6' { 'starter' }
    'grade-1-6-7' { 'easy' }
    'grade-2-7-8' { 'easy' }
    'grade-3-8-9' { 'medium' }
    default { 'upper-primary' }
  }
}

function Set-AutomaticCounts {
  param([string]$Value)
  switch ($Value) {
    'preschool-3-5' {
      $script:WordCount = 20; $script:SentenceCount = 4; $script:ComboCount = 8; $script:LessonCount = 1
    }
    'kindergarten-5-6' {
      $script:WordCount = 20; $script:SentenceCount = 6; $script:ComboCount = 8; $script:LessonCount = 1
    }
    'grade-1-6-7' {
      $script:WordCount = 20; $script:SentenceCount = 10; $script:ComboCount = 10; $script:LessonCount = 2
    }
    'grade-2-7-8' {
      $script:WordCount = 16; $script:SentenceCount = 12; $script:ComboCount = 8; $script:LessonCount = 2
    }
    'grade-3-8-9' {
      $script:WordCount = 12; $script:SentenceCount = 14; $script:ComboCount = 6; $script:LessonCount = 3
    }
    default {
      $script:WordCount = 10; $script:SentenceCount = 16; $script:ComboCount = 4; $script:LessonCount = 3
    }
  }
}

function Set-CoursePackCounts {
  param([string]$Value)
  switch ($Value) {
    'preschool-3-5' {
      $script:WordCount = 8; $script:SentenceCount = 4; $script:ComboCount = 6; $script:LessonCount = 1
    }
    'kindergarten-5-6' {
      $script:WordCount = 10; $script:SentenceCount = 5; $script:ComboCount = 6; $script:LessonCount = 1
    }
    'grade-1-6-7' {
      $script:WordCount = 12; $script:SentenceCount = 6; $script:ComboCount = 8; $script:LessonCount = 1
    }
    'grade-2-7-8' {
      $script:WordCount = 10; $script:SentenceCount = 8; $script:ComboCount = 6; $script:LessonCount = 2
    }
    'grade-3-8-9' {
      $script:WordCount = 8; $script:SentenceCount = 10; $script:ComboCount = 4; $script:LessonCount = 2
    }
    default {
      $script:WordCount = 8; $script:SentenceCount = 12; $script:ComboCount = 4; $script:LessonCount = 2
    }
  }
}

function Get-StageRank {
  param([string]$Value)
  $rank = @{
    'preschool-3-5' = 1
    'kindergarten-5-6' = 2
    'grade-1-6-7' = 3
    'grade-2-7-8' = 4
    'grade-3-8-9' = 5
    'primary-4-6-9-12' = 6
  }
  if ($rank.ContainsKey($Value)) { return $rank[$Value] }
  return 99
}

function Select-StageAppropriateRows {
  param($Rows, [string]$CurrentStage)
  $currentRank = Get-StageRank $CurrentStage
  return @($Rows | Where-Object { (Get-StageRank $_.stage) -le $currentRank })
}

function Get-UniqueRowsByEnglish {
  param($Rows)
  $seen = @{}
  $unique = New-Object System.Collections.Generic.List[object]
  foreach ($row in @($Rows)) {
    $key = "$($row.english)".Trim().ToLowerInvariant()
    if ($key -and -not $seen.ContainsKey($key)) {
      $seen[$key] = $true
      $unique.Add($row)
    }
  }
  return @($unique.ToArray())
}

function New-SentenceFromWord {
  param($WordRow)
  $english = "$($WordRow.english)"
  $meaning = "$($WordRow.meaning)"
  $phonetic = "$($WordRow.phonetic)".Trim('/')
  $key = Sanitize-Name $english
  $difficultyMode = if ($script:DifficultyMode -and $script:DifficultyMode -ne 'auto') { $script:DifficultyMode } else { $script:Difficulty }

  if ($key -match 'red|blue|yellow|green|pink|white|black|brown|purple|orange|big|small|long|short|happy|sad|hot|cold|good|nice|new|old|young|tall|fast|slow|clean|dirty|kind|funny|sunny|rainy|cloudy|windy|warm|cool') {
    return [pscustomobject]@{
      english = "It is $english."
      phonetic = "/ɪt ɪz $phonetic/"
      meaning = "它是$meaning`的。"
      phonetic_source = 'generated-template'
    }
  }

  if ($key -match 'run|jump|walk|sing|dance|play|eat|drink|sleep|smile|open|close|read|write|draw|listen|look|help|share|swim|ride|climb|wash|brush|cook|study|count|spell|speak|ask|answer|find|make|give|take|bring') {
    if ($difficultyMode -eq 'challenge') {
      return [pscustomobject]@{
        english = "Can you $english with me?"
        phonetic = "/kæn juː $phonetic wɪð miː/"
        meaning = "你能和我一起$meaning吗？"
        phonetic_source = 'generated-template'
      }
    }
    return [pscustomobject]@{
      english = "I can $english."
      phonetic = "/aɪ kæn $phonetic/"
      meaning = "我会$meaning。"
      phonetic_source = 'generated-template'
    }
  }

  $article = if ($english -match '^[aeiou]') { 'an' } else { 'a' }
  $articlePhonetic = if ($article -eq 'an') { 'ən' } else { 'ə' }
  if ($difficultyMode -eq 'challenge') {
    return [pscustomobject]@{
      english = "I can see the $english."
      phonetic = "/aɪ kæn siː ðə $phonetic/"
      meaning = "我能看见这个$meaning。"
      phonetic_source = 'generated-template'
    }
  }
  if ($difficultyMode -eq 'basic') {
    return [pscustomobject]@{
      english = "I like this $english."
      phonetic = "/aɪ laɪk ðɪs $phonetic/"
      meaning = "我喜欢这个$meaning。"
      phonetic_source = 'generated-template'
    }
  }
  return [pscustomobject]@{
    english = "This is $article $english."
    phonetic = "/ðɪs ɪz $articlePhonetic $phonetic/"
    meaning = "这是一个$meaning。"
    phonetic_source = 'generated-template'
  }
}

function Set-BuiltInPreset {
  param([string]$Value)
  $presets = @{
    'preschool-daily' = @{ system = 'domestic'; level = 'domestic-preschool'; stage = 'preschool-3-5'; theme = 'general'; difficulty = 'starter'; visual = 'storybook' }
    'preschool-animals' = @{ system = 'domestic'; level = 'domestic-preschool'; stage = 'preschool-3-5'; theme = 'zoo-animals'; difficulty = 'starter'; visual = 'storybook' }
    'preschool-breakfast' = @{ system = 'domestic'; level = 'domestic-preschool'; stage = 'preschool-3-5'; theme = 'breakfast'; difficulty = 'starter'; visual = 'storybook' }
    'preschool-family' = @{ system = 'domestic'; level = 'domestic-preschool'; stage = 'preschool-3-5'; theme = 'family'; difficulty = 'starter'; visual = 'storybook' }
    'preschool-bedtime' = @{ system = 'domestic'; level = 'domestic-preschool'; stage = 'preschool-3-5'; theme = 'bedtime'; difficulty = 'starter'; visual = 'storybook' }
    'kindergarten-animals' = @{ system = 'domestic'; level = 'domestic-preschool'; stage = 'kindergarten-5-6'; theme = 'zoo-animals'; difficulty = 'starter'; visual = 'storybook' }
    'kindergarten-classroom' = @{ system = 'domestic'; level = 'domestic-preschool'; stage = 'kindergarten-5-6'; theme = 'classroom'; difficulty = 'starter'; visual = 'storybook' }
    'kindergarten-breakfast' = @{ system = 'domestic'; level = 'domestic-preschool'; stage = 'kindergarten-5-6'; theme = 'breakfast'; difficulty = 'starter'; visual = 'storybook' }
    'kindergarten-family' = @{ system = 'domestic'; level = 'domestic-preschool'; stage = 'kindergarten-5-6'; theme = 'family'; difficulty = 'starter'; visual = 'storybook' }
    'grade1-classroom' = @{ system = 'domestic'; level = 'domestic-grade-1-2'; stage = 'grade-1-6-7'; theme = 'classroom'; difficulty = 'basic'; visual = 'storybook' }
    'grade1-animals' = @{ system = 'domestic'; level = 'domestic-grade-1-2'; stage = 'grade-1-6-7'; theme = 'zoo-animals'; difficulty = 'basic'; visual = 'watercolor' }
    'grade1-breakfast' = @{ system = 'domestic'; level = 'domestic-grade-1-2'; stage = 'grade-1-6-7'; theme = 'breakfast'; difficulty = 'basic'; visual = 'storybook' }
    'grade1-family' = @{ system = 'domestic'; level = 'domestic-grade-1-2'; stage = 'grade-1-6-7'; theme = 'family'; difficulty = 'basic'; visual = 'storybook' }
    'grade1-weather' = @{ system = 'domestic'; level = 'domestic-grade-1-2'; stage = 'grade-1-6-7'; theme = 'weather'; difficulty = 'basic'; visual = 'storybook' }
    'grade1-park' = @{ system = 'domestic'; level = 'domestic-grade-1-2'; stage = 'grade-1-6-7'; theme = 'park-play'; difficulty = 'basic'; visual = 'watercolor' }
    'grade1-cleaning' = @{ system = 'domestic'; level = 'domestic-grade-1-2'; stage = 'grade-1-6-7'; theme = 'cleaning-room'; difficulty = 'basic'; visual = 'storybook' }
    'grade2-classroom' = @{ system = 'domestic'; level = 'domestic-grade-1-2'; stage = 'grade-2-7-8'; theme = 'classroom'; difficulty = 'basic'; visual = 'storybook' }
    'grade2-animals' = @{ system = 'domestic'; level = 'domestic-grade-1-2'; stage = 'grade-2-7-8'; theme = 'zoo-animals'; difficulty = 'basic'; visual = 'watercolor' }
    'grade2-weather' = @{ system = 'domestic'; level = 'domestic-grade-1-2'; stage = 'grade-2-7-8'; theme = 'weather'; difficulty = 'basic'; visual = 'storybook' }
    'prea1-animals' = @{ system = 'international'; level = 'pre-a1'; stage = 'grade-1-6-7'; theme = 'zoo-animals'; difficulty = 'starter'; visual = 'storybook' }
    'prea1-daily' = @{ system = 'international'; level = 'pre-a1'; stage = 'grade-1-6-7'; theme = 'family'; difficulty = 'starter'; visual = 'storybook' }
  }
  if (-not $presets.ContainsKey($Value)) { return }
  $preset = $presets[$Value]
  $script:System = $preset.system
  $script:Level = $preset.level
  $script:Stage = $preset.stage
  $script:Theme = $preset.theme
  $script:CompletePack = $true
  $script:AutoCounts = $true
  $script:DifficultyMode = $preset.difficulty
  $script:VisualStyle = $preset.visual
}

if ($Preset) {
  Set-BuiltInPreset $Preset
  $System = $script:System
  $Level = $script:Level
  $Stage = $script:Stage
  $Theme = $script:Theme
  $CompletePack = $script:CompletePack
  $AutoCounts = $script:AutoCounts
  $DifficultyMode = $script:DifficultyMode
  $VisualStyle = $script:VisualStyle
  $script:VisualStyle = $VisualStyle
}

$levelResolution = Resolve-LearningLevel -RequestedSystem $System -RequestedLevel $Level -RequestedStage $Stage
$System = $levelResolution.system
$Level = $levelResolution.level
$Stage = $levelResolution.stage
$Difficulty = Get-Difficulty $Stage
$script:DifficultyMode = $DifficultyMode
if ($DifficultyMode -ne 'auto') { $Difficulty = $DifficultyMode }
$script:Difficulty = $Difficulty

if ($AutoCounts) {
  Set-AutomaticCounts $Stage
}

if ($FormalCompletePack) {
  $CompletePack = $true
  $StrictAssets = $true
  $StrictContent = $true
  $PhoneticPolicy = 'curated-only'
}

if ($ThemePack) {
  $CoursePack = $true
  $PrintLayout = $true
}

if ($CompletePack) {
  $CoursePack = $true
  $PrintLayout = $true
  $SevenDayPack = $true
  $ActivityPack = $true
  $ActivityImages = $true
  $PhonicsPack = $true
  $LearningRecord = $true
  $ExportZip = $true
  $Mode = 'mixed'
}

if ($CoursePack) {
  $Mode = 'mixed'
  Set-CoursePackCounts $Stage
}

function New-Font {
  param([string]$Name, [float]$Size, [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular)
  try { return [System.Drawing.Font]::new($Name, $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel) }
  catch { return [System.Drawing.Font]::new('Arial', $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel) }
}

function Add-RoundedRect {
  param([System.Drawing.Graphics]$G, [System.Drawing.Brush]$Brush, [float]$X, [float]$Y, [float]$W, [float]$H, [float]$R)
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $R * 2
  $path.AddArc($X, $Y, $d, $d, 180, 90)
  $path.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)
  $path.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)
  $path.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  $G.FillPath($Brush, $path)
  $path.Dispose()
}

function Draw-CenteredText {
  param(
    [System.Drawing.Graphics]$G,
    [string]$Text,
    [System.Drawing.Font]$Font,
    [System.Drawing.Brush]$Brush,
    [float]$X,
    [float]$Y,
    [float]$W,
    [float]$H
  )
  $format = [System.Drawing.StringFormat]::new()
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $format.Trimming = [System.Drawing.StringTrimming]::Word
  $rect = [System.Drawing.RectangleF]::new($X, $Y, $W, $H)
  $G.DrawString($Text, $Font, $Brush, $rect, $format)
  $format.Dispose()
}

function Get-AdaptiveFontSize {
  param(
    [string]$Text,
    [int]$Preferred,
    [int]$Minimum,
    [int]$SoftLimit,
    [int]$Step = 4
  )
  $length = if ($Text) { $Text.Trim().Length } else { 0 }
  if ($length -le $SoftLimit) {
    return $Preferred
  }

  $overflow = $length - $SoftLimit
  $size = $Preferred - [Math]::Ceiling($overflow / [Math]::Max(1, $Step))
  return [Math]::Max($Minimum, [int]$size)
}

function Draw-TextBox {
  param(
    [System.Drawing.Graphics]$G,
    [string]$Text,
    [System.Drawing.Font]$Font,
    [System.Drawing.Brush]$Brush,
    [float]$X,
    [float]$Y,
    [float]$W,
    [float]$H,
    [System.Drawing.StringAlignment]$Align = [System.Drawing.StringAlignment]::Center,
    [System.Drawing.StringAlignment]$LineAlign = [System.Drawing.StringAlignment]::Near
  )
  $format = [System.Drawing.StringFormat]::new()
  $format.Alignment = $Align
  $format.LineAlignment = $LineAlign
  $format.Trimming = [System.Drawing.StringTrimming]::Word
  $format.FormatFlags = 0
  $rect = [System.Drawing.RectangleF]::new($X, $Y, $W, $H)
  $G.DrawString($Text, $Font, $Brush, $rect, $format)
  $format.Dispose()
}

function Draw-PageBase {
  param([System.Drawing.Graphics]$G, [int]$Width, [int]$Height)
  $G.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $G.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $bgColor = switch ($script:VisualStyle) {
    'icon' { [System.Drawing.Color]::FromArgb(255, 250, 253, 255) }
    'watercolor' { [System.Drawing.Color]::FromArgb(255, 255, 250, 240) }
    default { [System.Drawing.Color]::FromArgb(255, 255, 248, 232) }
  }
  $bg = [System.Drawing.SolidBrush]::new($bgColor)
  $G.FillRectangle($bg, 0, 0, $Width, $Height)
  $bg.Dispose()

  $colors = switch ($script:VisualStyle) {
    'icon' {
      @(
        [System.Drawing.Color]::FromArgb(255, 119, 201, 212),
        [System.Drawing.Color]::FromArgb(255, 138, 199, 164),
        [System.Drawing.Color]::FromArgb(255, 246, 200, 95)
      )
    }
    'watercolor' {
      @(
        [System.Drawing.Color]::FromArgb(255, 177, 214, 190),
        [System.Drawing.Color]::FromArgb(255, 255, 218, 153),
        [System.Drawing.Color]::FromArgb(255, 245, 184, 158),
        [System.Drawing.Color]::FromArgb(255, 172, 219, 230),
        [System.Drawing.Color]::FromArgb(255, 201, 187, 230)
      )
    }
    default {
      @(
        [System.Drawing.Color]::FromArgb(255, 138, 199, 164),
        [System.Drawing.Color]::FromArgb(255, 246, 200, 95),
        [System.Drawing.Color]::FromArgb(255, 247, 160, 114),
        [System.Drawing.Color]::FromArgb(255, 119, 201, 212),
        [System.Drawing.Color]::FromArgb(255, 180, 160, 218)
      )
    }
  }
  $decorationCount = if ($script:VisualStyle -eq 'icon') { 10 } else { 18 }
  for ($i = 0; $i -lt $decorationCount; $i++) {
    $brush = [System.Drawing.SolidBrush]::new($colors[$i % $colors.Count])
    $x = if ($i % 2 -eq 0) { 30 + (($i * 73) % 190) } else { 850 + (($i * 41) % 140) }
    $y = 60 + (($i * 137) % 1400)
    $G.FillEllipse($brush, $x, $y, 34 + (($i * 7) % 34), 34 + (($i * 5) % 34))
    $brush.Dispose()
  }
}

function Draw-BookIcon {
  param([System.Drawing.Graphics]$G, [float]$X, [float]$Y, [float]$W, [float]$H)
  $cover = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 119, 201, 212))
  $page = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 252, 242))
  $line = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104), 7)
  $softLine = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 138, 199, 164), 4)
  Add-RoundedRect $G $cover ($X + $W * 0.16) ($Y + $H * 0.18) ($W * 0.68) ($H * 0.58) 28
  Add-RoundedRect $G $page ($X + $W * 0.20) ($Y + $H * 0.22) ($W * 0.28) ($H * 0.48) 20
  Add-RoundedRect $G $page ($X + $W * 0.52) ($Y + $H * 0.22) ($W * 0.28) ($H * 0.48) 20
  $G.DrawLine($line, $X + $W * 0.50, $Y + $H * 0.23, $X + $W * 0.50, $Y + $H * 0.72)
  for ($i = 0; $i -lt 3; $i++) {
    $yy = $Y + $H * (0.34 + $i * 0.11)
    $G.DrawLine($softLine, $X + $W * 0.25, $yy, $X + $W * 0.43, $yy)
    $G.DrawLine($softLine, $X + $W * 0.57, $yy, $X + $W * 0.75, $yy)
  }
  $cover.Dispose(); $page.Dispose(); $line.Dispose(); $softLine.Dispose()
}

function Draw-PencilIcon {
  param([System.Drawing.Graphics]$G, [float]$X, [float]$Y, [float]$W, [float]$H)
  $body = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 246, 200, 95))
  $eraser = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 247, 160, 114))
  $wood = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 223, 162))
  $lead = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 38, 54, 74))
  $line = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104), 5)
  Add-RoundedRect $G $body ($X + $W * 0.22) ($Y + $H * 0.42) ($W * 0.46) ($H * 0.18) 18
  Add-RoundedRect $G $eraser ($X + $W * 0.14) ($Y + $H * 0.42) ($W * 0.10) ($H * 0.18) 12
  $points = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new($X + $W * 0.68, $Y + $H * 0.42),
    [System.Drawing.PointF]::new($X + $W * 0.84, $Y + $H * 0.51),
    [System.Drawing.PointF]::new($X + $W * 0.68, $Y + $H * 0.60)
  )
  $G.FillPolygon($wood, $points)
  $leadPoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new($X + $W * 0.80, $Y + $H * 0.47),
    [System.Drawing.PointF]::new($X + $W * 0.86, $Y + $H * 0.51),
    [System.Drawing.PointF]::new($X + $W * 0.80, $Y + $H * 0.55)
  )
  $G.FillPolygon($lead, $leadPoints)
  $G.DrawLine($line, $X + $W * 0.30, $Y + $H * 0.44, $X + $W * 0.30, $Y + $H * 0.58)
  $body.Dispose(); $eraser.Dispose(); $wood.Dispose(); $lead.Dispose(); $line.Dispose()
}

function Draw-BagIcon {
  param([System.Drawing.Graphics]$G, [float]$X, [float]$Y, [float]$W, [float]$H)
  $bag = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 247, 160, 114))
  $pocket = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 248, 232))
  $line = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104), 7)
  Add-RoundedRect $G $bag ($X + $W * 0.28) ($Y + $H * 0.28) ($W * 0.44) ($H * 0.46) 32
  $G.DrawArc($line, $X + $W * 0.36, $Y + $H * 0.14, $W * 0.28, $H * 0.24, 200, 140)
  Add-RoundedRect $G $pocket ($X + $W * 0.36) ($Y + $H * 0.48) ($W * 0.28) ($H * 0.18) 18
  $G.DrawLine($line, $X + $W * 0.36, $Y + $H * 0.39, $X + $W * 0.64, $Y + $H * 0.39)
  $bag.Dispose(); $pocket.Dispose(); $line.Dispose()
}

function Draw-FruitIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $fruitColor = if ($Keyword -match 'apple') { [System.Drawing.Color]::FromArgb(255, 216, 107, 92) } elseif ($Keyword -match 'banana') { [System.Drawing.Color]::FromArgb(255, 246, 200, 95) } else { [System.Drawing.Color]::FromArgb(255, 247, 160, 114) }
  $fruit = [System.Drawing.SolidBrush]::new($fruitColor)
  $leaf = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 138, 199, 164))
  $stem = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 75, 51, 42), 6)
  if ($Keyword -match 'banana') {
    $pen = [System.Drawing.Pen]::new($fruitColor, 44)
    $G.DrawArc($pen, $X + $W * 0.24, $Y + $H * 0.22, $W * 0.52, $H * 0.50, 25, 135)
    $pen.Dispose()
  } else {
    $G.FillEllipse($fruit, $X + $W * 0.34, $Y + $H * 0.26, $W * 0.32, $H * 0.38)
    $G.FillEllipse($fruit, $X + $W * 0.40, $Y + $H * 0.24, $W * 0.28, $H * 0.40)
  }
  $G.DrawLine($stem, $X + $W * 0.51, $Y + $H * 0.25, $X + $W * 0.54, $Y + $H * 0.16)
  $G.FillEllipse($leaf, $X + $W * 0.55, $Y + $H * 0.14, $W * 0.16, $H * 0.08)
  $fruit.Dispose(); $leaf.Dispose(); $stem.Dispose()
}

function Draw-AnimalIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $faceColor = if ($Keyword -eq 'panda') { [System.Drawing.Color]::White } elseif ($Keyword -eq 'monkey') { [System.Drawing.Color]::FromArgb(255, 188, 137, 91) } elseif ($Keyword -eq 'elephant') { [System.Drawing.Color]::FromArgb(255, 157, 187, 199) } elseif ($Keyword -eq 'mouse') { [System.Drawing.Color]::FromArgb(255, 190, 198, 207) } elseif ($Keyword -eq 'frog') { [System.Drawing.Color]::FromArgb(255, 138, 199, 164) } elseif ($Keyword -eq 'zebra') { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(255, 246, 200, 95) }
  $face = [System.Drawing.SolidBrush]::new($faceColor)
  $dark = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 38, 54, 74))
  $pink = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 247, 160, 114))
  $brown = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 130, 91, 66))
  $line = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104), 5)

  if ($Keyword -in @('animal','pet')) {
    $leftColor = if ($Keyword -eq 'pet') { $face } else { $brown }
    $rightColor = if ($Keyword -eq 'pet') { $brown } else { $face }
    $G.FillEllipse($leftColor, $X + $W * 0.22, $Y + $H * 0.30, $W * 0.26, $H * 0.27)
    $G.FillEllipse($rightColor, $X + $W * 0.52, $Y + $H * 0.30, $W * 0.26, $H * 0.27)
    $catEar1 = [System.Drawing.PointF[]]@(
      [System.Drawing.PointF]::new($X + $W * 0.23, $Y + $H * 0.37),
      [System.Drawing.PointF]::new($X + $W * 0.28, $Y + $H * 0.20),
      [System.Drawing.PointF]::new($X + $W * 0.35, $Y + $H * 0.34)
    )
    $catEar2 = [System.Drawing.PointF[]]@(
      [System.Drawing.PointF]::new($X + $W * 0.35, $Y + $H * 0.34),
      [System.Drawing.PointF]::new($X + $W * 0.42, $Y + $H * 0.20),
      [System.Drawing.PointF]::new($X + $W * 0.47, $Y + $H * 0.37)
    )
    $G.FillPolygon($leftColor, $catEar1); $G.FillPolygon($leftColor, $catEar2)
    $G.FillEllipse($brown, $X + $W * 0.49, $Y + $H * 0.27, $W * 0.11, $H * 0.20)
    $G.FillEllipse($brown, $X + $W * 0.70, $Y + $H * 0.27, $W * 0.11, $H * 0.20)
    foreach ($eyeX in @(0.30,0.40,0.60,0.70)) {
      $G.FillEllipse($dark, $X + $W * $eyeX, $Y + $H * 0.41, $W * 0.025, $H * 0.03)
    }
    $G.FillEllipse($pink, $X + $W * 0.35, $Y + $H * 0.48, $W * 0.035, $H * 0.025)
    $G.FillEllipse($dark, $X + $W * 0.64, $Y + $H * 0.48, $W * 0.045, $H * 0.035)
    $face.Dispose(); $dark.Dispose(); $pink.Dispose(); $brown.Dispose(); $line.Dispose()
    return
  } elseif ($Keyword -eq 'rabbit') {
    $G.FillEllipse($face, $X + $W * 0.34, $Y + $H * 0.10, $W * 0.11, $H * 0.30)
    $G.FillEllipse($face, $X + $W * 0.55, $Y + $H * 0.10, $W * 0.11, $H * 0.30)
  } elseif ($Keyword -eq 'cat') {
    $leftEar = [System.Drawing.PointF[]]@(
      [System.Drawing.PointF]::new($X + $W * 0.31, $Y + $H * 0.38),
      [System.Drawing.PointF]::new($X + $W * 0.36, $Y + $H * 0.16),
      [System.Drawing.PointF]::new($X + $W * 0.45, $Y + $H * 0.34)
    )
    $rightEar = [System.Drawing.PointF[]]@(
      [System.Drawing.PointF]::new($X + $W * 0.55, $Y + $H * 0.34),
      [System.Drawing.PointF]::new($X + $W * 0.64, $Y + $H * 0.16),
      [System.Drawing.PointF]::new($X + $W * 0.69, $Y + $H * 0.38)
    )
    $G.FillPolygon($face, $leftEar); $G.FillPolygon($face, $rightEar)
  } elseif ($Keyword -eq 'dog') {
    $G.FillEllipse($brown, $X + $W * 0.22, $Y + $H * 0.25, $W * 0.18, $H * 0.30)
    $G.FillEllipse($brown, $X + $W * 0.60, $Y + $H * 0.25, $W * 0.18, $H * 0.30)
  } elseif ($Keyword -eq 'panda') {
    $G.FillEllipse($dark, $X + $W * 0.27, $Y + $H * 0.20, $W * 0.15, $H * 0.16)
    $G.FillEllipse($dark, $X + $W * 0.58, $Y + $H * 0.20, $W * 0.15, $H * 0.16)
  } elseif ($Keyword -eq 'monkey') {
    $G.FillEllipse($brown, $X + $W * 0.22, $Y + $H * 0.32, $W * 0.18, $H * 0.20)
    $G.FillEllipse($brown, $X + $W * 0.60, $Y + $H * 0.32, $W * 0.18, $H * 0.20)
  } elseif ($Keyword -eq 'elephant') {
    $G.FillEllipse($face, $X + $W * 0.20, $Y + $H * 0.25, $W * 0.25, $H * 0.32)
    $G.FillEllipse($face, $X + $W * 0.55, $Y + $H * 0.25, $W * 0.25, $H * 0.32)
  } elseif ($Keyword -eq 'giraffe') {
    $G.FillRectangle($face, $X + $W * 0.43, $Y + $H * 0.12, $W * 0.14, $H * 0.32)
    $G.FillEllipse($brown, $X + $W * 0.40, $Y + $H * 0.10, $W * 0.05, $H * 0.09)
    $G.FillEllipse($brown, $X + $W * 0.56, $Y + $H * 0.10, $W * 0.05, $H * 0.09)
  } elseif ($Keyword -eq 'mouse') {
    $G.FillEllipse($face, $X + $W * 0.23, $Y + $H * 0.20, $W * 0.20, $H * 0.22)
    $G.FillEllipse($face, $X + $W * 0.57, $Y + $H * 0.20, $W * 0.20, $H * 0.22)
  } elseif ($Keyword -eq 'frog') {
    $G.FillEllipse($face, $X + $W * 0.31, $Y + $H * 0.18, $W * 0.16, $H * 0.18)
    $G.FillEllipse($face, $X + $W * 0.53, $Y + $H * 0.18, $W * 0.16, $H * 0.18)
  } else {
    $G.FillEllipse($face, $X + $W * 0.25, $Y + $H * 0.24, $W * 0.16, $H * 0.16)
    $G.FillEllipse($face, $X + $W * 0.59, $Y + $H * 0.24, $W * 0.16, $H * 0.16)
  }
  $G.FillEllipse($face, $X + $W * 0.32, $Y + $H * 0.26, $W * 0.36, $H * 0.34)
  $G.FillEllipse($dark, $X + $W * 0.41, $Y + $H * 0.40, $W * 0.045, $H * 0.05)
  $G.FillEllipse($dark, $X + $W * 0.56, $Y + $H * 0.40, $W * 0.045, $H * 0.05)
  $G.FillEllipse($pink, $X + $W * 0.47, $Y + $H * 0.49, $W * 0.07, $H * 0.045)
  if ($Keyword -eq 'cat') {
    $G.DrawLine($line, $X + $W * 0.31, $Y + $H * 0.48, $X + $W * 0.20, $Y + $H * 0.44)
    $G.DrawLine($line, $X + $W * 0.69, $Y + $H * 0.48, $X + $W * 0.80, $Y + $H * 0.44)
  } elseif ($Keyword -eq 'dog') {
    $G.FillEllipse($dark, $X + $W * 0.46, $Y + $H * 0.50, $W * 0.08, $H * 0.07)
    $G.DrawArc($line, $X + $W * 0.42, $Y + $H * 0.52, $W * 0.16, $H * 0.10, 0, 180)
  } elseif ($Keyword -eq 'panda') {
    $G.FillEllipse($dark, $X + $W * 0.37, $Y + $H * 0.35, $W * 0.11, $H * 0.14)
    $G.FillEllipse($dark, $X + $W * 0.52, $Y + $H * 0.35, $W * 0.11, $H * 0.14)
  } elseif ($Keyword -eq 'monkey') {
    $muzzle = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 218, 153))
    $G.FillEllipse($muzzle, $X + $W * 0.40, $Y + $H * 0.44, $W * 0.20, $H * 0.15)
    $muzzle.Dispose()
  } elseif ($Keyword -eq 'elephant') {
    Add-RoundedRect $G $face ($X + $W * 0.45) ($Y + $H * 0.48) ($W * 0.10) ($H * 0.28) 18
  } elseif ($Keyword -eq 'giraffe') {
    for ($i = 0; $i -lt 4; $i++) {
      $G.FillEllipse($brown, $X + $W * (0.38 + ($i % 2) * 0.17), $Y + $H * (0.28 + [Math]::Floor($i / 2) * 0.17), $W * 0.06, $H * 0.07)
    }
  } elseif ($Keyword -eq 'zebra') {
    for ($i = 0; $i -lt 4; $i++) {
      $yy = $Y + $H * (0.30 + $i * 0.08)
      $G.DrawLine($line, $X + $W * 0.35, $yy, $X + $W * 0.46, $yy + $H * 0.05)
      $G.DrawLine($line, $X + $W * 0.54, $yy + $H * 0.05, $X + $W * 0.65, $yy)
    }
  } elseif ($Keyword -eq 'mouse') {
    $G.FillEllipse($pink, $X + $W * 0.47, $Y + $H * 0.49, $W * 0.06, $H * 0.04)
    $G.DrawLine($line, $X + $W * 0.32, $Y + $H * 0.48, $X + $W * 0.20, $Y + $H * 0.45)
    $G.DrawLine($line, $X + $W * 0.68, $Y + $H * 0.48, $X + $W * 0.80, $Y + $H * 0.45)
    $G.DrawArc($line, $X + $W * 0.67, $Y + $H * 0.48, $W * 0.18, $H * 0.18, 270, 180)
  } elseif ($Keyword -eq 'frog') {
    $G.FillEllipse($dark, $X + $W * 0.36, $Y + $H * 0.25, $W * 0.07, $H * 0.07)
    $G.FillEllipse($dark, $X + $W * 0.57, $Y + $H * 0.25, $W * 0.07, $H * 0.07)
    $G.DrawArc($line, $X + $W * 0.39, $Y + $H * 0.43, $W * 0.22, $H * 0.13, 0, 180)
  }
  $face.Dispose(); $dark.Dispose(); $pink.Dispose(); $brown.Dispose(); $line.Dispose()
}

function Draw-WeatherIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $sun = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 246, 200, 95))
  $cloud = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
  $rain = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 119, 201, 212), 7)
  if ($Keyword -match 'moon') {
    $G.FillEllipse($sun, $X + $W * 0.39, $Y + $H * 0.25, $W * 0.28, $H * 0.34)
    $cut = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 234, 247, 255))
    $G.FillEllipse($cut, $X + $W * 0.48, $Y + $H * 0.20, $W * 0.24, $H * 0.34)
    $cut.Dispose()
  } elseif ($Keyword -match 'rain|cloud') {
    $G.FillEllipse($cloud, $X + $W * 0.30, $Y + $H * 0.32, $W * 0.22, $H * 0.18)
    $G.FillEllipse($cloud, $X + $W * 0.44, $Y + $H * 0.25, $W * 0.24, $H * 0.24)
    $G.FillEllipse($cloud, $X + $W * 0.57, $Y + $H * 0.34, $W * 0.18, $H * 0.16)
    if ($Keyword -match 'rain') {
      for ($i = 0; $i -lt 3; $i++) {
        $xx = $X + $W * (0.38 + $i * 0.11)
        $G.DrawLine($rain, $xx, $Y + $H * 0.58, $xx - 12, $Y + $H * 0.70)
      }
    }
  } else {
    $G.FillEllipse($sun, $X + $W * 0.38, $Y + $H * 0.28, $W * 0.28, $H * 0.28)
  }
  $sun.Dispose(); $cloud.Dispose(); $rain.Dispose()
}

function Draw-AssetIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  if (-not $Keyword) { return $false }
  $safe = Sanitize-Name $Keyword
  $iconDir = Join-Path $SkillRoot 'assets\icons'
  $candidates = @(
    (Join-Path $VerifiedAssetDir "$safe.png"),
    (Join-Path $VerifiedAssetDir "$safe.jpg"),
    (Join-Path $VerifiedAssetDir "$safe.jpeg"),
    (Join-Path $VerifiedAssetDir "$safe.webp"),
    (Join-Path $AssetDir "$safe.png"),
    (Join-Path $AssetDir "$safe.jpg"),
    (Join-Path $AssetDir "$safe.jpeg"),
    (Join-Path $AssetDir "$safe.webp"),
    (Join-Path $iconDir "$safe.png"),
    (Join-Path $iconDir "$safe.jpg"),
    (Join-Path $iconDir "$safe.jpeg")
  )
  $iconPath = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  if (-not $iconPath) { return $false }

  $img = [System.Drawing.Image]::FromFile($iconPath)
  $maxW = $W * 0.64
  $maxH = $H * 0.60
  $scale = [Math]::Min($maxW / $img.Width, $maxH / $img.Height)
  $drawW = $img.Width * $scale
  $drawH = $img.Height * $scale
  $drawX = $X + ($W - $drawW) / 2
  $drawY = $Y + $H * 0.10 + (($maxH - $drawH) / 2)
  $G.DrawImage($img, $drawX, $drawY, $drawW, $drawH)
  $img.Dispose()
  return $true
}

function Draw-ColorIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $colorMap = @{
    'red' = [System.Drawing.Color]::FromArgb(255, 216, 107, 92)
    'blue' = [System.Drawing.Color]::FromArgb(255, 119, 201, 212)
    'yellow' = [System.Drawing.Color]::FromArgb(255, 246, 200, 95)
    'green' = [System.Drawing.Color]::FromArgb(255, 138, 199, 164)
    'pink' = [System.Drawing.Color]::FromArgb(255, 255, 183, 197)
    'white' = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
    'black' = [System.Drawing.Color]::FromArgb(255, 38, 54, 74)
    'brown' = [System.Drawing.Color]::FromArgb(255, 130, 91, 66)
    'purple' = [System.Drawing.Color]::FromArgb(255, 125, 106, 159)
    'orange' = [System.Drawing.Color]::FromArgb(255, 247, 160, 114)
  }
  $c = if ($colorMap.ContainsKey($Keyword)) { $colorMap[$Keyword] } else { [System.Drawing.Color]::FromArgb(255, 119, 201, 212) }
  $brush = [System.Drawing.SolidBrush]::new($c)
  $pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104), 5)
  $G.FillEllipse($brush, $X + $W * 0.34, $Y + $H * 0.22, $W * 0.32, $H * 0.38)
  $G.DrawEllipse($pen, $X + $W * 0.34, $Y + $H * 0.22, $W * 0.32, $H * 0.38)
  $brush.Dispose(); $pen.Dispose()
}

function Draw-HomeIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $main = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 252, 242))
  $accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 247, 160, 114))
  $line = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104), 6)
  if ($Keyword -match 'chair') {
    Add-RoundedRect $G $accent ($X + $W * 0.35) ($Y + $H * 0.28) ($W * 0.30) ($H * 0.24) 18
    $G.DrawLine($line, $X + $W * 0.38, $Y + $H * 0.52, $X + $W * 0.34, $Y + $H * 0.70)
    $G.DrawLine($line, $X + $W * 0.62, $Y + $H * 0.52, $X + $W * 0.66, $Y + $H * 0.70)
  } elseif ($Keyword -match 'bed') {
    Add-RoundedRect $G $accent ($X + $W * 0.24) ($Y + $H * 0.42) ($W * 0.52) ($H * 0.20) 16
    Add-RoundedRect $G $main ($X + $W * 0.26) ($Y + $H * 0.34) ($W * 0.18) ($H * 0.12) 10
    $G.DrawLine($line, $X + $W * 0.24, $Y + $H * 0.62, $X + $W * 0.24, $Y + $H * 0.72)
    $G.DrawLine($line, $X + $W * 0.76, $Y + $H * 0.62, $X + $W * 0.76, $Y + $H * 0.72)
  } elseif ($Keyword -match 'door|window') {
    Add-RoundedRect $G $main ($X + $W * 0.34) ($Y + $H * 0.20) ($W * 0.32) ($H * 0.46) 12
    if ($Keyword -match 'door') { $G.FillEllipse($accent, $X + $W * 0.56, $Y + $H * 0.42, $W * 0.04, $H * 0.04) }
    else {
      $G.DrawLine($line, $X + $W * 0.50, $Y + $H * 0.20, $X + $W * 0.50, $Y + $H * 0.66)
      $G.DrawLine($line, $X + $W * 0.34, $Y + $H * 0.43, $X + $W * 0.66, $Y + $H * 0.43)
    }
  } else {
    $roof = [System.Drawing.PointF[]]@(
      [System.Drawing.PointF]::new($X + $W * 0.24, $Y + $H * 0.42),
      [System.Drawing.PointF]::new($X + $W * 0.50, $Y + $H * 0.20),
      [System.Drawing.PointF]::new($X + $W * 0.76, $Y + $H * 0.42)
    )
    $G.FillPolygon($accent, $roof)
    Add-RoundedRect $G $main ($X + $W * 0.30) ($Y + $H * 0.40) ($W * 0.40) ($H * 0.28) 12
  }
  $main.Dispose(); $accent.Dispose(); $line.Dispose()
}

function Draw-TransportIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $body = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 119, 201, 212))
  $accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 246, 200, 95))
  $dark = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 38, 54, 74))
  if ($Keyword -match 'plane') {
    $points = [System.Drawing.PointF[]]@(
      [System.Drawing.PointF]::new($X + $W * 0.20, $Y + $H * 0.52),
      [System.Drawing.PointF]::new($X + $W * 0.82, $Y + $H * 0.36),
      [System.Drawing.PointF]::new($X + $W * 0.62, $Y + $H * 0.55),
      [System.Drawing.PointF]::new($X + $W * 0.82, $Y + $H * 0.70)
    )
    $G.FillPolygon($body, $points)
  } elseif ($Keyword -match 'boat') {
    $G.FillPie($body, $X + $W * 0.24, $Y + $H * 0.40, $W * 0.52, $H * 0.34, 0, 180)
    $G.FillRectangle($accent, $X + $W * 0.48, $Y + $H * 0.25, $W * 0.04, $H * 0.22)
  } else {
    Add-RoundedRect $G $body ($X + $W * 0.24) ($Y + $H * 0.36) ($W * 0.52) ($H * 0.24) 18
    $G.FillEllipse($dark, $X + $W * 0.32, $Y + $H * 0.57, $W * 0.10, $H * 0.10)
    $G.FillEllipse($dark, $X + $W * 0.58, $Y + $H * 0.57, $W * 0.10, $H * 0.10)
  }
  $body.Dispose(); $accent.Dispose(); $dark.Dispose()
}

function Draw-NatureIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $green = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 138, 199, 164))
  $brown = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 130, 91, 66))
  $accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 246, 200, 95))
  $blue = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 119, 201, 212), 8)
  if ($Keyword -match 'flower') {
    for ($i = 0; $i -lt 6; $i++) {
      $angle = $i * [Math]::PI / 3
      $px = $X + $W * 0.50 + [Math]::Cos($angle) * $W * 0.11
      $py = $Y + $H * 0.38 + [Math]::Sin($angle) * $H * 0.10
      $G.FillEllipse($green, $px - 22, $py - 18, 44, 36)
    }
    $G.FillEllipse($accent, $X + $W * 0.46, $Y + $H * 0.34, $W * 0.08, $H * 0.08)
  } elseif ($Keyword -match 'river|lake|ocean|beach') {
    $G.DrawArc($blue, $X + $W * 0.25, $Y + $H * 0.40, $W * 0.50, $H * 0.22, 0, 180)
    $G.DrawArc($blue, $X + $W * 0.30, $Y + $H * 0.50, $W * 0.42, $H * 0.18, 0, 180)
  } elseif ($Keyword -match 'mountain') {
    $points = [System.Drawing.PointF[]]@(
      [System.Drawing.PointF]::new($X + $W * 0.25, $Y + $H * 0.66),
      [System.Drawing.PointF]::new($X + $W * 0.50, $Y + $H * 0.24),
      [System.Drawing.PointF]::new($X + $W * 0.76, $Y + $H * 0.66)
    )
    $G.FillPolygon($green, $points)
  } else {
    $G.FillRectangle($brown, $X + $W * 0.47, $Y + $H * 0.40, $W * 0.07, $H * 0.28)
    $G.FillEllipse($green, $X + $W * 0.34, $Y + $H * 0.20, $W * 0.32, $H * 0.30)
  }
  $green.Dispose(); $brown.Dispose(); $accent.Dispose(); $blue.Dispose()
}

function Draw-PeopleIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $skin = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 246, 200, 95))
  $shirt = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 119, 201, 212))
  $hair = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 75, 51, 42))
  $G.FillEllipse($skin, $X + $W * 0.40, $Y + $H * 0.24, $W * 0.20, $H * 0.22)
  $G.FillPie($hair, $X + $W * 0.39, $Y + $H * 0.20, $W * 0.22, $H * 0.18, 180, 180)
  Add-RoundedRect $G $shirt ($X + $W * 0.35) ($Y + $H * 0.48) ($W * 0.30) ($H * 0.22) 20
  if ($Keyword -match 'family|friend|team|group|community') {
    $G.FillEllipse($skin, $X + $W * 0.24, $Y + $H * 0.34, $W * 0.14, $H * 0.16)
    $G.FillEllipse($skin, $X + $W * 0.64, $Y + $H * 0.34, $W * 0.14, $H * 0.16)
  }
  $skin.Dispose(); $shirt.Dispose(); $hair.Dispose()
}

function Draw-BodyIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $skin = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 246, 200, 95))
  $dark = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 38, 54, 74))
  if ($Keyword -match 'eye') {
    $G.FillEllipse($skin, $X + $W * 0.30, $Y + $H * 0.34, $W * 0.40, $H * 0.20)
    $G.FillEllipse($dark, $X + $W * 0.45, $Y + $H * 0.38, $W * 0.10, $H * 0.10)
  } elseif ($Keyword -match 'hand|finger') {
    Add-RoundedRect $G $skin ($X + $W * 0.36) ($Y + $H * 0.36) ($W * 0.28) ($H * 0.26) 24
  } elseif ($Keyword -match 'foot|shoe|sock') {
    Add-RoundedRect $G $skin ($X + $W * 0.30) ($Y + $H * 0.45) ($W * 0.44) ($H * 0.16) 30
  } else {
    $G.FillEllipse($skin, $X + $W * 0.36, $Y + $H * 0.22, $W * 0.28, $H * 0.32)
    $G.FillEllipse($dark, $X + $W * 0.43, $Y + $H * 0.36, $W * 0.04, $H * 0.05)
    $G.FillEllipse($dark, $X + $W * 0.54, $Y + $H * 0.36, $W * 0.04, $H * 0.05)
  }
  $skin.Dispose(); $dark.Dispose()
}

function Draw-ShapeNumberIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 180, 160, 218))
  $line = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104), 6)
  if ($Keyword -match 'triangle') {
    $points = [System.Drawing.PointF[]]@(
      [System.Drawing.PointF]::new($X + $W * 0.50, $Y + $H * 0.22),
      [System.Drawing.PointF]::new($X + $W * 0.28, $Y + $H * 0.62),
      [System.Drawing.PointF]::new($X + $W * 0.72, $Y + $H * 0.62)
    )
    $G.FillPolygon($accent, $points)
  } elseif ($Keyword -match 'square') {
    Add-RoundedRect $G $accent ($X + $W * 0.34) ($Y + $H * 0.28) ($W * 0.32) ($H * 0.32) 12
  } elseif ($Keyword -match 'circle') {
    $G.FillEllipse($accent, $X + $W * 0.34, $Y + $H * 0.26, $W * 0.32, $H * 0.36)
  } else {
    $G.DrawLine($line, $X + $W * 0.30, $Y + $H * 0.58, $X + $W * 0.70, $Y + $H * 0.32)
  }
  $accent.Dispose(); $line.Dispose()
}

function Draw-ActionIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $body = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104), 8)
  $accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 246, 200, 95))
  $G.FillEllipse($accent, $X + $W * 0.44, $Y + $H * 0.22, $W * 0.12, $H * 0.12)
  $G.DrawLine($body, $X + $W * 0.50, $Y + $H * 0.34, $X + $W * 0.50, $Y + $H * 0.54)
  $G.DrawLine($body, $X + $W * 0.50, $Y + $H * 0.42, $X + $W * 0.34, $Y + $H * 0.50)
  $G.DrawLine($body, $X + $W * 0.50, $Y + $H * 0.42, $X + $W * 0.66, $Y + $H * 0.50)
  if ($Keyword -match 'run|walk|jump|dance|swim|climb|kick') {
    $G.DrawLine($body, $X + $W * 0.50, $Y + $H * 0.54, $X + $W * 0.36, $Y + $H * 0.70)
    $G.DrawLine($body, $X + $W * 0.50, $Y + $H * 0.54, $X + $W * 0.66, $Y + $H * 0.68)
  } else {
    $G.DrawLine($body, $X + $W * 0.50, $Y + $H * 0.54, $X + $W * 0.42, $Y + $H * 0.70)
    $G.DrawLine($body, $X + $W * 0.50, $Y + $H * 0.54, $X + $W * 0.58, $Y + $H * 0.70)
  }
  $body.Dispose(); $accent.Dispose()
}

function Draw-StudyIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  if ($Keyword -match 'computer|keyboard|screen|internet|technology|camera|battery') {
    $screen = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 119, 201, 212))
    $line = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104), 6)
    Add-RoundedRect $G $screen ($X + $W * 0.28) ($Y + $H * 0.24) ($W * 0.44) ($H * 0.30) 18
    $G.DrawLine($line, $X + $W * 0.50, $Y + $H * 0.54, $X + $W * 0.50, $Y + $H * 0.65)
    $G.DrawLine($line, $X + $W * 0.40, $Y + $H * 0.66, $X + $W * 0.60, $Y + $H * 0.66)
    $screen.Dispose(); $line.Dispose()
  } else {
    Draw-BookIcon $G $X $Y $W $H
  }
}

function Draw-ConceptIcon {
  param([System.Drawing.Graphics]$G, [string]$Keyword, [float]$X, [float]$Y, [float]$W, [float]$H)
  $accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 246, 200, 95))
  $line = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104), 6)
  $G.FillEllipse($accent, $X + $W * 0.40, $Y + $H * 0.18, $W * 0.20, $H * 0.22)
  $G.DrawLine($line, $X + $W * 0.42, $Y + $H * 0.50, $X + $W * 0.58, $Y + $H * 0.50)
  $G.DrawLine($line, $X + $W * 0.44, $Y + $H * 0.58, $X + $W * 0.56, $Y + $H * 0.58)
  $G.DrawLine($line, $X + $W * 0.47, $Y + $H * 0.66, $X + $W * 0.53, $Y + $H * 0.66)
  $accent.Dispose(); $line.Dispose()
}

function Draw-MissingVisualCue {
  param([System.Drawing.Graphics]$G, [float]$X, [float]$Y, [float]$W, [float]$H)
  $line = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 216, 107, 92), 5)
  $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 216, 107, 92))
  $G.DrawRectangle($line, $X + $W * 0.34, $Y + $H * 0.20, $W * 0.32, $H * 0.30)
  $G.DrawLine($line, $X + $W * 0.36, $Y + $H * 0.47, $X + $W * 0.47, $Y + $H * 0.34)
  $G.DrawLine($line, $X + $W * 0.47, $Y + $H * 0.34, $X + $W * 0.55, $Y + $H * 0.42)
  $G.DrawLine($line, $X + $W * 0.55, $Y + $H * 0.42, $X + $W * 0.64, $Y + $H * 0.30)
  $font = New-Font 'Microsoft YaHei' 30 ([System.Drawing.FontStyle]::Bold)
  Draw-CenteredText $G '待补对应图片' $font $brush ($X + 40) ($Y + $H * 0.52) ($W - 80) ($H * 0.16)
  $font.Dispose(); $line.Dispose(); $brush.Dispose()
}

function Draw-VisualCue {
  param([System.Drawing.Graphics]$G, [string]$Label, [float]$X, [float]$Y, [float]$W, [float]$H, [string]$Keyword = '')
  $tile = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 234, 247, 255))
  Add-RoundedRect $G $tile $X $Y $W $H 36
  $tile.Dispose()

  $key = Normalize-LevelKey $Keyword
  if ($key -eq 'orange' -and $Label -match '橙|橘') { $key = 'orange-fruit' }
  $visualSource = Get-VisualSource $Keyword
  $hasIcon = $false
  if ($visualSource -eq 'missing') {
    Draw-MissingVisualCue $G $X $Y $W $H
  } elseif (Draw-AssetIcon $G $key $X $Y $W $H) {
    $hasIcon = $true
  } elseif ($key -match 'red|blue|yellow|green|pink|white|black|brown|purple|^orange$|color') {
    Draw-ColorIcon $G $key $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'book|notebook|story|page|letter|word|sentence|question|answer|chapter|library|magazine|newspaper|paragraph|vocabulary|grammar|language|english|math|science|history|geography|subject|homework|lesson|paper|map|board|music|song|art|paint|drawing|painting|report|project|education|knowledge|information') {
    Draw-BookIcon $G $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'pencil|pen|crayon|ruler|eraser|marker|glue|write|draw') {
    Draw-PencilIcon $G $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'bag|backpack') {
    Draw-BagIcon $G $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'apple|orange-fruit|banana|pear|grape|fruit|peach|melon|lemon|strawberry|watermelon|pineapple|bread|cake|rice|noodles|cookie|milk|water|egg|soup|chicken|juice|breakfast|lunch|dinner|vegetable|carrot|potato|tomato|corn|cheese|hungry|thirsty|eat|drink|cook') {
    Draw-FruitIcon $G $key $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'cat|dog|rabbit|panda|monkey|bird|fish|duck|cow|pig|sheep|horse|bear|lion|tiger|elephant|giraffe|zebra|turtle|animal|pet|mouse|frog|snake|fox|wolf|deer|goat|hen') {
    Draw-AnimalIcon $G $key $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'sun|moon|cloud|rain|weather|star|sky|wind|snow|sunny|rainy|cloudy|windy|storm|rainbow|temperature|season|spring|summer|autumn|winter|hot|cold|warm|cool') {
    Draw-WeatherIcon $G $key $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'chair|table|desk|door|window|clock|picture|home|room|bed|sofa|lamp|kitchen|bathroom|house') {
    Draw-HomeIcon $G $key $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'car|train|bus|taxi|plane|boat|subway|bicycle|helmet|traffic|station|road|street|airport|passport|journey|travel|visitor|direction|distance') {
    Draw-TransportIcon $G $key $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'tree|flower|leaf|grass|garden|park|forest|mountain|river|lake|ocean|island|beach|desert|field|path|nature|earth|planet|space|climate|environment|pollution|recycle|resource|plant') {
    Draw-NatureIcon $G $key $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'mom|dad|baby|friend|teacher|family|mother|father|sister|brother|grandma|grandpa|child|doctor|nurse|driver|farmer|worker|artist|singer|player|police|cook|volunteer|team|group|community') {
    Draw-PeopleIcon $G $key $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'eye|ear|nose|mouth|hand|foot|head|face|hair|tummy|arm|leg|shirt|coat|hat|shoe|sock|dress|tooth|shoulder|knee|finger|heart|health|medicine|sick') {
    Draw-BodyIcon $G $key $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'circle|square|triangle|shape|line|number|one|two|three|four|five|six|seven|eight|nine|above|under|between|behind|next|near|far|left|right-side|front|big|small|long|short|tall|full|empty') {
    Draw-ShapeNumberIcon $G $key $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'run|jump|walk|sing|dance|play|sleep|smile|open|close|read|listen|look|help|clean|share|swim|ride|climb|throw|catch|wash|brush|study|count|spell|speak|ask|find|make|give|take|bring|choose|finish|practice|remember|forget|borrow|return|visit|wait|cross|build|carry|collect|decide|explain|learn|move|protect|compare|describe|discover|improve|prepare|realize|receive|reduce|repeat|suggest|understand') {
    Draw-ActionIcon $G $key $X $Y $W $H; $hasIcon = $true
  } elseif ($key -match 'computer|keyboard|screen|internet|technology|camera|battery|experiment|energy') {
    Draw-StudyIcon $G $key $X $Y $W $H; $hasIcon = $true
  } else {
    Draw-MissingVisualCue $G $X $Y $W $H
  }

  $labelFontSize = if ($H -lt 190) { 31 } elseif ($H -lt 230) { 36 } else { 44 }
  $font = New-Font 'Microsoft YaHei' $labelFontSize ([System.Drawing.FontStyle]::Bold)
  $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104))
  if ($hasIcon) {
    $labelTop = $Y + $H * 0.72
    $labelHeight = $H * 0.24
    Draw-CenteredText $G $Label $font $brush ($X + 24) $labelTop ($W - 48) $labelHeight
  } else {
    Draw-CenteredText $G $Label $font $brush ($X + 30) ($Y + $H * 0.52) ($W - 60) ($H * 0.25)
  }
  $brush.Dispose()
  $font.Dispose()
}

function Save-Card {
  param(
    [string]$FileName,
    [scriptblock]$Draw
  )
  $width = 1080
  $height = 1620
  $bmp = [System.Drawing.Bitmap]::new($width, $height)
  $g = [System.Drawing.Graphics]::FromImage($bmp)

  if ($BackgroundImage -and (Test-Path -LiteralPath $BackgroundImage)) {
    $bg = [System.Drawing.Image]::FromFile($BackgroundImage)
    $g.DrawImage($bg, 0, 0, $width, $height)
    $bg.Dispose()
  } else {
    Draw-PageBase $g $width $height
  }

  $panel = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(240, 255, 255, 255))
  Add-RoundedRect $g $panel 110 120 860 1340 42
  $panel.Dispose()

  & $Draw $g

  $path = Join-Path $OutputDir $FileName
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
  return $path
}

function New-WordCard {
  param($Row, [int]$Index, [switch]$Combo)
  $indexText = '{0:D3}' -f $Index
  $safeName = Sanitize-Name $Row.english
  $cardType = if ($Combo) { 'combo' } else { 'word' }
  $name = "$cardType-$indexText-$safeName.png"
  $path = Save-Card $name {
    param($g)
    $main = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104))
    $ipa = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 125, 106, 159))
    $cn = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 216, 107, 92))
    $sub = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 38, 54, 74))

    Draw-VisualCue $g $Row.meaning 260 210 560 360 $Row.english
    Draw-CenteredText $g $Row.english (New-Font 'Segoe UI' 104 ([System.Drawing.FontStyle]::Bold)) $main 140 610 800 140
    Draw-CenteredText $g $Row.phonetic (New-Font 'Segoe UI' 46) $ipa 140 750 800 80
    Draw-CenteredText $g $Row.meaning (New-Font 'Microsoft YaHei' 64 ([System.Drawing.FontStyle]::Bold)) $cn 140 830 800 100
    if (-not $Combo -and $Row.PSObject.Properties.Name -contains 'example' -and $Row.example) {
      $exampleText = "$($Row.example)"
      $exampleMeaning = "$($Row.example_meaning)"
      $exampleEnglishSize = Get-AdaptiveFontSize $exampleText 56 38 26 5
      $exampleChineseSize = Get-AdaptiveFontSize $exampleMeaning 46 34 18 4
      Draw-CenteredText $g $exampleText (New-Font 'Segoe UI' $exampleEnglishSize ([System.Drawing.FontStyle]::Bold)) $sub 135 970 810 120
      Draw-CenteredText $g $exampleMeaning (New-Font 'Microsoft YaHei' $exampleChineseSize) $cn 135 1092 810 96
    }
    if ($Combo) {
      if ($script:DifficultyMode -and $script:DifficultyMode -ne 'auto') {
        $generatedCombo = New-SentenceFromWord $Row
        $sentence = $generatedCombo.english
        $meaning = $generatedCombo.meaning
      } else {
        $sentence = if ($Row.PSObject.Properties.Name -contains 'example' -and $Row.example) { $Row.example } else { "I see $($Row.english)." }
        $meaning = if ($Row.PSObject.Properties.Name -contains 'example_meaning' -and $Row.example_meaning) { $Row.example_meaning } else { "我看见$($Row.meaning)。" }
      }
      $comboEnglishSize = Get-AdaptiveFontSize $sentence 58 40 30 5
      $comboChineseSize = Get-AdaptiveFontSize $meaning 48 34 20 4
      Draw-CenteredText $g $sentence (New-Font 'Segoe UI' $comboEnglishSize ([System.Drawing.FontStyle]::Bold)) $sub 135 970 810 130
      Draw-CenteredText $g $meaning (New-Font 'Microsoft YaHei' $comboChineseSize) $cn 135 1105 810 105
    }

    $main.Dispose(); $ipa.Dispose(); $cn.Dispose(); $sub.Dispose()
  }
  return [pscustomobject]@{ type = $cardType; english = $Row.english; phonetic = $Row.phonetic; meaning = $Row.meaning; phonetic_source = 'curated-word'; file = $path }
}

function New-SentenceCard {
  param($Row, [int]$Index)
  $indexText = '{0:D3}' -f $Index
  $safeName = Sanitize-Name $Row.english
  $name = "sentence-$indexText-$safeName.png"
  $path = Save-Card $name {
    param($g)
    $main = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104))
    $ipa = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 125, 106, 159))
    $cn = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 216, 107, 92))

    Draw-VisualCue $g '跟读' 300 230 480 270
    $sentenceEnglishSize = Get-AdaptiveFontSize $Row.english 82 56 28 5
    $sentenceIpaSize = Get-AdaptiveFontSize $Row.phonetic 46 36 34 5
    $sentenceChineseSize = Get-AdaptiveFontSize $Row.meaning 62 44 20 4
    Draw-CenteredText $g $Row.english (New-Font 'Segoe UI' $sentenceEnglishSize ([System.Drawing.FontStyle]::Bold)) $main 130 570 820 270
    Draw-CenteredText $g $Row.phonetic (New-Font 'Segoe UI' $sentenceIpaSize) $ipa 140 845 800 115
    Draw-CenteredText $g $Row.meaning (New-Font 'Microsoft YaHei' $sentenceChineseSize ([System.Drawing.FontStyle]::Bold)) $cn 130 970 820 190

    $main.Dispose(); $ipa.Dispose(); $cn.Dispose()
  }
  $phoneticSource = if ($Row.PSObject.Properties.Name -contains 'phonetic_source' -and $Row.phonetic_source) { $Row.phonetic_source } else { 'curated-bank' }
  return [pscustomobject]@{ type = 'sentence'; english = $Row.english; phonetic = $Row.phonetic; meaning = $Row.meaning; phonetic_source = $phoneticSource; file = $path }
}

function New-LessonPage {
  param($Rows, [int]$Index)
  $lessonTitle = if ($Title) { $Title } else { $script:ThemeLabel }
  $indexText = '{0:D3}' -f $Index
  $safeName = Sanitize-Name $lessonTitle
  $name = "lesson-$indexText-$safeName.png"
  $path = Save-Card $name {
    param($g)
    $main = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104))
    $cn = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 75, 51, 42))
    $accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 216, 107, 92))
    $rowCount = [Math]::Max(1, $Rows.Count)
    $maxEnglishLength = ($Rows | ForEach-Object { "$($_.english)".Length } | Measure-Object -Maximum).Maximum
    $maxPhoneticLength = ($Rows | ForEach-Object { "$($_.phonetic)".Length } | Measure-Object -Maximum).Maximum
    $maxMeaningLength = ($Rows | ForEach-Object { "$($_.meaning)".Length } | Measure-Object -Maximum).Maximum
    $titleSize = if ($lessonTitle.Length -gt 24) { 42 } elseif ($lessonTitle.Length -gt 16) { 48 } else { 54 }
    $baseEnglishSize = if ($rowCount -le 4) { 42 } elseif ($rowCount -le 6) { 36 } else { 31 }
    if ($maxEnglishLength -gt 58) { $baseEnglishSize -= 8 } elseif ($maxEnglishLength -gt 42) { $baseEnglishSize -= 4 }
    $baseEnglishSize = [Math]::Max(25, $baseEnglishSize)
    $baseIpaSize = [Math]::Max(20, [int]($baseEnglishSize * 0.70))
    if ($maxPhoneticLength -gt 58) { $baseIpaSize = [Math]::Max(18, $baseIpaSize - 4) }
    $baseChineseSize = [Math]::Max(23, [int]($baseEnglishSize * 0.82))
    if ($maxMeaningLength -gt 28) { $baseChineseSize = [Math]::Max(21, $baseChineseSize - 3) }

    $titleFont = New-Font 'Segoe UI' $titleSize ([System.Drawing.FontStyle]::Bold)
    $engFont = New-Font 'Segoe UI' $baseEnglishSize ([System.Drawing.FontStyle]::Bold)
    $ipaFont = New-Font 'Segoe UI' $baseIpaSize
    $cnFont = New-Font 'Microsoft YaHei' $baseChineseSize
    $numFont = New-Font 'Segoe UI' ([Math]::Min(52, [Math]::Max(34, $baseEnglishSize + 12))) ([System.Drawing.FontStyle]::Bold)

    $titleTop = 155
    $titleHeight = 90
    $contentTop = 285
    $contentBottom = if ($rowCount -le 5) { 1135 } else { 1245 }
    $availableHeight = $contentBottom - $contentTop
    $rowGap = if ($rowCount -le 4) { 22 } elseif ($rowCount -le 6) { 15 } else { 10 }
    $slotHeight = ($availableHeight - (($rowCount - 1) * $rowGap)) / $rowCount
    $englishHeight = [Math]::Max(38, $slotHeight * 0.42)
    $ipaHeight = [Math]::Max(28, $slotHeight * 0.23)
    $meaningHeight = [Math]::Max(30, $slotHeight * 0.25)
    $numberWidth = 76
    $textX = 235
    $textW = 640

    Draw-CenteredText $g ("{0:D2}  {1}" -f $Index, $lessonTitle) $titleFont $accent 150 $titleTop 780 $titleHeight
    $ipa = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 125, 106, 159))
    $y = $contentTop
    $n = 1
    foreach ($row in $Rows) {
      Draw-TextBox $g ("$n") $numFont $accent 155 ($y + 4) $numberWidth ([Math]::Min(64, $slotHeight)) ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Near)
      Draw-TextBox $g $row.english $engFont $main $textX $y $textW $englishHeight ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Near)
      Draw-TextBox $g $row.phonetic $ipaFont $ipa $textX ($y + $englishHeight + 2) $textW $ipaHeight ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Near)
      Draw-TextBox $g $row.meaning $cnFont $cn $textX ($y + $englishHeight + $ipaHeight + 6) $textW $meaningHeight ([System.Drawing.StringAlignment]::Center) ([System.Drawing.StringAlignment]::Near)
      $y += $slotHeight + $rowGap
      $n += 1
    }
    $footerTop = $y + 18
    if ($footerTop -lt 1310) {
      $footerHeight = [Math]::Min(150, 1425 - $footerTop)
      if ($footerHeight -ge 90) {
        Draw-VisualCue $g '复习' 325 $footerTop 430 $footerHeight
      }
    }
    $main.Dispose(); $cn.Dispose(); $accent.Dispose(); $ipa.Dispose()
    $numFont.Dispose(); $titleFont.Dispose(); $engFont.Dispose(); $ipaFont.Dispose(); $cnFont.Dispose()
  }
  $lessonPhonetic = ($Rows | ForEach-Object { "$($_.phonetic)" } | Where-Object { $_.Trim() } | Select-Object -First 8) -join ' | '
  $lessonPhoneticSource = if (@($Rows | Where-Object { $_.PSObject.Properties.Name -contains 'phonetic_source' -and $_.phonetic_source -eq 'generated-template' }).Count -gt 0) { 'mixed-with-generated' } else { 'curated-bank' }
  return [pscustomobject]@{ type = 'lesson'; english = $lessonTitle; phonetic = $lessonPhonetic; meaning = "$($Rows.Count) sentence pairs"; phonetic_source = $lessonPhoneticSource; file = $path }
}

$themeKey = if ($Theme -and $Theme -ne 'general') { Normalize-Theme $Theme } else { 'general' }
$script:ThemeKey = $themeKey
$script:ThemeLabel = Get-ThemeDisplayName $themeKey
$recommendedThemesPath = Join-Path $OutputDir 'recommended-themes.csv'
Get-RecommendedThemes $Stage | Export-CsvForExcel -Path $recommendedThemesPath
if ($RecommendThemesOnly) {
  Write-Output "Recommended themes only. No cards generated."
  Write-Output "Recommended themes: $recommendedThemesPath"
  return
}
$words = @()
$sentences = @()
$wordSource = 'stage-bank'
$sentenceSource = 'stage-bank'

if ($themeKey -ne 'general' -and (Test-Path -LiteralPath $ThemePackPath)) {
  $themeWords = Get-RowsFromMarkdownCsv -Path $ThemePackPath -Header 'kind,theme,stage,english,phonetic,meaning,example,example_meaning' -Prefix "word,$themeKey"
  $themeSentences = Get-RowsFromMarkdownCsv -Path $ThemePackPath -Header 'kind,theme,stage,english,phonetic,meaning,example,example_meaning' -Prefix "sentence,$themeKey"
  $words = Select-StageAppropriateRows $themeWords $Stage
  $sentences = Select-StageAppropriateRows $themeSentences $Stage
  if ($words.Count -gt 0) { $wordSource = 'theme-pack' }
  if ($sentences.Count -gt 0) { $sentenceSource = 'theme-pack' }
}

if (-not $words -or $words.Count -eq 0) {
  $words = Get-RowsFromMarkdownCsv -Path $WordBankPath -Header 'preset,english,phonetic,meaning' -Prefix $Stage
  $words = Sort-RowsByTheme $words $themeKey
  $wordSource = 'stage-bank'
}

if (-not $sentences -or $sentences.Count -eq 0) {
  $sentences = Get-RowsFromMarkdownCsv -Path $SentenceBankPath -Header 'preset,type,english,phonetic,meaning,example,example_meaning' -Prefix "$Stage,sentence"
  $sentenceSource = 'stage-bank'
}

$words = Get-UniqueRowsByEnglish $words
$sentences = Get-UniqueRowsByEnglish $sentences

$neededWordRows = [Math]::Max($WordCount, $ComboCount)
if ($words.Count -lt $neededWordRows) {
  $stageWords = Get-RowsFromMarkdownCsv -Path $WordBankPath -Header 'preset,english,phonetic,meaning' -Prefix $Stage
  $stageWords = Sort-RowsByTheme $stageWords $themeKey
  $seenWords = @{}
  foreach ($row in $words) { $seenWords[$row.english.ToLowerInvariant()] = $true }
  foreach ($row in $stageWords) {
    $key = $row.english.ToLowerInvariant()
    if (-not $seenWords.ContainsKey($key)) {
      $words += $row
      $seenWords[$key] = $true
    }
    if ($words.Count -ge $neededWordRows) { break }
  }
  if ($wordSource -eq 'theme-pack' -and $words.Count -ge $neededWordRows) { $wordSource = 'theme-pack+stage-bank' }
}

$neededSentenceRows = [Math]::Max($SentenceCount, ([Math]::Max(1, $LessonCount) * 8))
if ($sentences.Count -lt $neededSentenceRows) {
  $stageSentences = Get-RowsFromMarkdownCsv -Path $SentenceBankPath -Header 'preset,type,english,phonetic,meaning,example,example_meaning' -Prefix "$Stage,sentence"
  $seenSentences = @{}
  foreach ($row in $sentences) { $seenSentences[$row.english.ToLowerInvariant()] = $true }
  foreach ($row in $stageSentences) {
    $key = $row.english.ToLowerInvariant()
    if (-not $seenSentences.ContainsKey($key)) {
      $sentences += $row
      $seenSentences[$key] = $true
    }
    if ($sentences.Count -ge $neededSentenceRows) { break }
  }
  if ($sentenceSource -eq 'theme-pack' -and $sentences.Count -ge $neededSentenceRows) { $sentenceSource = 'theme-pack+stage-bank' }
}

if ($PhoneticPolicy -eq 'allow-generated' -and $sentences.Count -lt $neededSentenceRows -and $words.Count -gt 0) {
  $seenSentences = @{}
  foreach ($row in $sentences) { $seenSentences[$row.english.ToLowerInvariant()] = $true }
  $wordIndex = 0
  while ($sentences.Count -lt $neededSentenceRows -and $wordIndex -lt ($words.Count * 3)) {
    $wordRow = $words[$wordIndex % $words.Count]
    $generated = New-SentenceFromWord $wordRow
    $key = $generated.english.ToLowerInvariant()
    if (-not $seenSentences.ContainsKey($key)) {
      $sentences += $generated
      $seenSentences[$key] = $true
    }
    $wordIndex += 1
  }
  if ($sentences.Count -ge $neededSentenceRows) {
    $sentenceSource = if ($sentenceSource -eq 'stage-bank') { 'stage-bank+generated' } else { "$sentenceSource+generated" }
  }
}

$preflightAssetsPath = Join-Path $OutputDir 'preflight-assets.csv'
$preflightReportPath = Join-Path $OutputDir 'preflight-report.csv'
$preflightAssetRows = @($words | ForEach-Object {
  $asset = Resolve-IllustrationAsset $_.english
  $verification = Get-AssetVerificationStatus $_.english $asset
  $safety = Get-AssetSafety $asset
  $visualSource = Get-VisualSource $_.english
  [pscustomobject]@{
    english = $_.english
    meaning = $_.meaning
    category = Get-AssetCategory $_.english
    expected_visual = Get-ExpectedVisualCue $_.english $_.meaning
    visual_source = $visualSource
    asset = $asset
    verification = $verification
    edge_status = $safety.status
    edge_hits = $safety.edge_hits
    dimensions = if ($safety.width -gt 0) { "$($safety.width)x$($safety.height)" } else { '' }
    generation_status = if ($visualSource -eq 'missing') { 'will-exclude' } elseif ($safety.status -eq 'needs-review') { 'needs-review' } else { 'ready' }
    note = $safety.note
  }
})
$preflightAssetRows | Export-CsvForExcel -Path $preflightAssetsPath
$readyWordCount = @($preflightAssetRows | Where-Object { $_.generation_status -eq 'ready' }).Count
$reviewWordCount = @($preflightAssetRows | Where-Object { $_.generation_status -eq 'needs-review' }).Count
$excludedWordCount = @($preflightAssetRows | Where-Object { $_.generation_status -eq 'will-exclude' }).Count
$requestedWordOutput = 0
if ($Mode -in @('word','mixed')) { $requestedWordOutput += $WordCount }
if ($Mode -in @('combo','mixed')) { $requestedWordOutput += $ComboCount }
$uniqueWordVisualsNeeded = 0
if ($Mode -in @('word','mixed')) { $uniqueWordVisualsNeeded = [Math]::Max($uniqueWordVisualsNeeded, $WordCount) }
if ($Mode -in @('combo','mixed')) { $uniqueWordVisualsNeeded = [Math]::Max($uniqueWordVisualsNeeded, $ComboCount) }
$preflightRows = @(
  [pscustomobject]@{ metric = 'word_output_cards'; requested = $requestedWordOutput; available = ([Math]::Min($WordCount, $readyWordCount) + [Math]::Min($ComboCount, $readyWordCount)); status = 'info'; note = '单词卡与组合卡的总输出数量' }
  [pscustomobject]@{ metric = 'unique_word_visuals'; requested = $uniqueWordVisualsNeeded; available = $readyWordCount; status = $(if ($readyWordCount -ge $uniqueWordVisualsNeeded) { 'ready' } else { 'reduced' }); note = '两类卡片可以复用同一批正确配图' }
  [pscustomobject]@{ metric = 'word_cards_possible'; requested = $(if ($Mode -in @('word','mixed')) { $WordCount } else { 0 }); available = $(if ($Mode -in @('word','mixed')) { [Math]::Min($WordCount, $readyWordCount) } else { 0 }); status = $(if ($Mode -notin @('word','mixed') -or $readyWordCount -ge $WordCount) { 'ready' } else { 'reduced' }); note = '预计可生成的单词卡数量' }
  [pscustomobject]@{ metric = 'combo_cards_possible'; requested = $(if ($Mode -in @('combo','mixed')) { $ComboCount } else { 0 }); available = $(if ($Mode -in @('combo','mixed')) { [Math]::Min($ComboCount, $readyWordCount) } else { 0 }); status = $(if ($Mode -notin @('combo','mixed') -or $readyWordCount -ge $ComboCount) { 'ready' } else { 'reduced' }); note = '预计可生成的单词加例句卡数量' }
  [pscustomobject]@{ metric = 'visuals_need_review'; requested = 0; available = $reviewWordCount; status = $(if ($reviewWordCount -eq 0) { 'ready' } else { 'needs-review' }); note = '素材可能贴边或截断' }
  [pscustomobject]@{ metric = 'visuals_will_exclude'; requested = 0; available = $excludedWordCount; status = $(if ($excludedWordCount -eq 0) { 'ready' } else { 'reduced' }); note = '缺图或动物素材未通过登记审核' }
  [pscustomobject]@{ metric = 'sentence_candidates'; requested = $SentenceCount; available = $sentences.Count; status = $(if ($sentences.Count -ge $SentenceCount) { 'ready' } else { 'reduced' }); note = $sentenceSource }
  [pscustomobject]@{ metric = 'asset_registry'; requested = 0; available = $script:VerifiedAssetRegistry.Count; status = $(if ($script:VerifiedAssetRegistry.Count -gt 0) { 'ready' } else { 'missing' }); note = '已审核素材登记数量' }
)
$preflightRows | Export-CsvForExcel -Path $preflightReportPath

$excludedVisualsPath = Join-Path $OutputDir 'excluded-visuals.csv'
$excludedVisualPromptsPath = Join-Path $OutputDir 'excluded-visual-prompts.txt'
if (Test-Path -LiteralPath $excludedVisualsPath) { Remove-Item -LiteralPath $excludedVisualsPath -Force }
if (Test-Path -LiteralPath $excludedVisualPromptsPath) { Remove-Item -LiteralPath $excludedVisualPromptsPath -Force }
if (-not $AssetCheckOnly -and -not $StrictAssets -and -not $AllowApproximateVisuals) {
  $excludedVisualRows = @($words | Where-Object { (Get-VisualSource $_.english) -eq 'missing' } | ForEach-Object {
    [pscustomobject]@{
      english = $_.english
      meaning = $_.meaning
      category = Get-AssetCategory $_.english
      required_filename = "$(Sanitize-Name $_.english).png"
      expected_visual = Get-ExpectedVisualCue $_.english $_.meaning
      asset_prompt = Get-AssetPrompt $_.english $_.meaning
      status = 'excluded-missing-visual'
    }
  })
  if ($excludedVisualRows.Count -gt 0) {
    $excludedVisualRows | Export-CsvForExcel -Path $excludedVisualsPath
    Write-AssetPromptPack -Rows $excludedVisualRows -Path $excludedVisualPromptsPath
    $words = @($words | Where-Object { (Get-VisualSource $_.english) -ne 'missing' })
  }
}

if (-not $words) { throw "No word rows found for stage $Stage." }
if (-not $sentences) { throw "No sentence rows found for stage $Stage." }

if ($StrictContent) {
  $missing = New-Object System.Collections.Generic.List[string]
  if ($Mode -in @('word','mixed') -and $words.Count -lt $WordCount) { $missing.Add("word: requested $WordCount, available $($words.Count)") }
  if ($Mode -in @('combo','mixed') -and $words.Count -lt $ComboCount) { $missing.Add("combo: requested $ComboCount, available $($words.Count)") }
  if ($Mode -in @('sentence','mixed') -and $sentences.Count -lt $SentenceCount) { $missing.Add("sentence: requested $SentenceCount, available $($sentences.Count)") }
  if ($Mode -in @('lesson','mixed')) {
    $pairsPerPageForCheck = if ($Stage -in @('preschool-3-5','kindergarten-5-6')) { 4 } elseif ($Stage -eq 'primary-4-6-9-12') { 7 } else { 6 }
    $requiredLessonRows = $LessonCount * $pairsPerPageForCheck
    if ($sentences.Count -lt $requiredLessonRows) { $missing.Add("lesson rows: requested $requiredLessonRows, available $($sentences.Count)") }
  }
  if ($missing.Count -gt 0) {
    throw "Strict content check failed: $($missing -join '; '). Reduce counts or allow generated content."
  }
}

if ($AssetCheckOnly) {
  $checkCount = [Math]::Max($WordCount, $ComboCount)
  if ($checkCount -lt 1) { $checkCount = 20 }
  $assetRows = @($words | Select-Object -First ([Math]::Min($checkCount, $words.Count)) | ForEach-Object {
    $asset = Resolve-IllustrationAsset $_.english
    $verification = Get-AssetVerificationStatus $_.english $asset
    $safety = Get-AssetSafety $asset
    $safeAssetName = "$(Sanitize-Name $_.english).png"
    [pscustomobject]@{
      english = $_.english
      meaning = $_.meaning
      category = Get-AssetCategory $_.english
      required_filename = $safeAssetName
      expected_visual = Get-ExpectedVisualCue $_.english $_.meaning
      asset_prompt = Get-AssetPrompt $_.english $_.meaning
      asset = $asset
      verification = $verification
      edge_status = $safety.status
      status = if (-not $asset) { 'needs-asset' } elseif ((Get-AssetCategory $_.english) -eq 'animals' -and $verification -ne 'verified') { 'needs-verification' } elseif ($safety.status -ne 'safe') { 'needs-edge-review' } else { 'ready' }
    }
  })
  $assetCheckPath = Join-Path $OutputDir 'asset-check.csv'
  $assetPromptPackPath = Join-Path $OutputDir 'asset-prompt-pack.txt'
  $assetRows | Export-CsvForExcel -Path $assetCheckPath
  Write-AssetPromptPack -Rows @($assetRows | Where-Object { $_.status -ne 'ready' }) -Path $assetPromptPackPath
  Write-Output "Asset check only. No cards generated."
  Write-Output "Preflight report: $preflightReportPath"
  Write-Output "Preflight assets: $preflightAssetsPath"
  Write-Output "Asset check: $assetCheckPath"
  if (Test-Path -LiteralPath $assetPromptPackPath) {
    Write-Output "Asset prompt pack: $assetPromptPackPath"
  }
  return
}

if ($StrictAssets -and -not $PlanOnly) {
  $strictCount = 0
  if ($Mode -in @('word','mixed')) { $strictCount = [Math]::Max($strictCount, $WordCount) }
  if ($Mode -in @('combo','mixed')) { $strictCount = [Math]::Max($strictCount, $ComboCount) }
  if ($strictCount -gt 0) {
    $strictRows = @($words | Select-Object -First ([Math]::Min($strictCount, $words.Count)) | ForEach-Object {
      $asset = Resolve-IllustrationAsset $_.english
      $verification = Get-AssetVerificationStatus $_.english $asset
      $safety = Get-AssetSafety $asset
      $safeAssetName = "$(Sanitize-Name $_.english).png"
      [pscustomobject]@{
        english = $_.english
        meaning = $_.meaning
        category = Get-AssetCategory $_.english
        required_filename = $safeAssetName
        expected_visual = Get-ExpectedVisualCue $_.english $_.meaning
        asset_prompt = Get-AssetPrompt $_.english $_.meaning
        asset = $asset
        verification = $verification
        edge_status = $safety.status
        status = if (-not $asset) { 'needs-asset' } elseif ((Get-AssetCategory $_.english) -eq 'animals' -and $verification -ne 'verified') { 'needs-verification' } elseif ($safety.status -ne 'safe') { 'needs-edge-review' } else { 'ready' }
      }
    })
    $missingAssets = @($strictRows | Where-Object { $_.status -ne 'ready' })
    if ($missingAssets.Count -gt 0) {
      $missingPath = Join-Path $OutputDir 'missing-assets.csv'
      $missingPromptPackPath = Join-Path $OutputDir 'missing-assets-prompts.txt'
      $missingAssets | Export-CsvForExcel -Path $missingPath
      Write-AssetPromptPack -Rows $missingAssets -Path $missingPromptPackPath
      Write-Output "Strict asset check failed. No cards generated."
      Write-Output "Missing assets: $missingPath"
      Write-Output "Missing asset prompts: $missingPromptPackPath"
      return
    }
  }
}

if ($PlanOnly) {
  $planRows = @(
    [pscustomobject]@{ item = 'system'; value = $System; note = '学习体系' }
    [pscustomobject]@{ item = 'level'; value = $Level; note = '学习分级' }
    [pscustomobject]@{ item = 'stage'; value = $Stage; note = '实际内容库' }
    [pscustomobject]@{ item = 'theme'; value = $script:ThemeLabel; note = $script:ThemeKey }
    [pscustomobject]@{ item = 'difficulty'; value = $Difficulty; note = '句子难度' }
    [pscustomobject]@{ item = 'word_cards'; value = $(if ($Mode -in @('word','mixed')) { [Math]::Min($WordCount, $words.Count) } else { 0 }); note = $wordSource }
    [pscustomobject]@{ item = 'sentence_cards'; value = $(if ($Mode -in @('sentence','mixed')) { $SentenceCount } else { 0 }); note = $sentenceSource }
    [pscustomobject]@{ item = 'combo_cards'; value = $(if ($Mode -in @('combo','mixed')) { [Math]::Min($ComboCount, $words.Count) } else { 0 }); note = $wordSource }
    [pscustomobject]@{ item = 'lesson_pages'; value = $(if ($Mode -in @('lesson','mixed')) { $LessonCount } else { 0 }); note = '每页按阶段自动放 4-8 组短句' }
    [pscustomobject]@{ item = 'formal_asset_tip'; value = 'assets/illustrations'; note = '正式版优先使用固定素材，缺素材时先报告' }
  )
  $planPath = Join-Path $OutputDir 'generation-plan.csv'
  $planRows | Export-CsvForExcel -Path $planPath
  $planTextPath = Join-Path $OutputDir 'generation-plan.txt'
  @"
生成前方案
主题：$($script:ThemeLabel)
体系：$System
分级：$Level
阶段：$Stage
难度：$Difficulty
模式：$Mode
单词卡：$($(if ($Mode -in @('word','mixed')) { [Math]::Min($WordCount, $words.Count) } else { 0 }))
短句卡：$($(if ($Mode -in @('sentence','mixed')) { $SentenceCount } else { 0 }))
组合卡：$($(if ($Mode -in @('combo','mixed')) { [Math]::Min($ComboCount, $words.Count) } else { 0 }))
学习页：$($(if ($Mode -in @('lesson','mixed')) { $LessonCount } else { 0 }))
配图规则：正式版优先使用 assets/illustrations 固定素材；缺少素材时先报告，不使用无关图标替代。
"@ | Set-Content -LiteralPath $planTextPath -Encoding UTF8
  Write-Output "Plan only. No cards generated."
  Write-Output "Generation plan: $planPath"
  Write-Output "Generation plan text: $planTextPath"
  return
}

$manifest = New-Object System.Collections.Generic.List[object]

if ($Mode -in @('word','mixed')) {
  for ($i = 0; $i -lt [Math]::Min($WordCount, $words.Count); $i++) {
    $manifest.Add((New-WordCard -Row $words[$i] -Index ($i + 1)))
  }
}

if ($Mode -in @('sentence','mixed')) {
  for ($i = 0; $i -lt [Math]::Min($SentenceCount, $sentences.Count); $i++) {
    $manifest.Add((New-SentenceCard -Row $sentences[$i] -Index ($i + 1)))
  }
}

if ($Mode -in @('combo','mixed')) {
  for ($i = 0; $i -lt [Math]::Min($ComboCount, $words.Count); $i++) {
    $manifest.Add((New-WordCard -Row $words[$i] -Index ($i + 1) -Combo))
  }
}

if ($Mode -in @('lesson','mixed')) {
  $pairsPerPage = if ($Stage -in @('preschool-3-5','kindergarten-5-6')) { 4 } elseif ($Stage -eq 'primary-4-6-9-12') { 7 } else { 6 }
  for ($i = 0; $i -lt $LessonCount; $i++) {
    $start = $i * $pairsPerPage
    if ($start -ge $sentences.Count) { break }
    $end = [Math]::Min($start + $pairsPerPage - 1, $sentences.Count - 1)
    $pageRows = @($sentences[$start..$end])
    $manifest.Add((New-LessonPage -Rows $pageRows -Index ($i + 1)))
  }
}

$manifestPath = Join-Path $OutputDir 'manifest.csv'
$taggedManifest = @($manifest | ForEach-Object {
  $source = if ($_.type -in @('word','combo')) { $wordSource } else { $sentenceSource }
  [pscustomobject]@{
    type = $_.type
    system = $System
    level = $Level
    stage = $Stage
    theme = $script:ThemeKey
    skill = $_.type
    difficulty = $Difficulty
    source = $source
    phonetic_source = if ($_.PSObject.Properties.Name -contains 'phonetic_source' -and $_.phonetic_source) { $_.phonetic_source } else { 'curated-bank' }
    english = $_.english
    phonetic = $_.phonetic
    meaning = $_.meaning
    visual_cue = if ($_.type -in @('word','combo')) { Get-ExpectedVisualCue $_.english $_.meaning } else { '' }
    visual_source = if ($_.type -in @('word','combo')) { Get-VisualSource $_.english } else { 'not-required' }
    file = $_.file
  }
})
$taggedManifest | Export-CsvForExcel -Path $manifestPath

$visualCoveragePath = Join-Path $OutputDir 'visual-coverage.csv'
$visualCoverageRows = @($taggedManifest | Where-Object { $_.type -in @('word','combo') } | ForEach-Object {
  $coverageAsset = Resolve-IllustrationAsset $_.english
  $coverageSafety = Get-AssetSafety $coverageAsset
  [pscustomobject]@{
    type = $_.type
    english = $_.english
    meaning = $_.meaning
    visual_source = $_.visual_source
    expected_visual = $_.visual_cue
    status = if ($_.visual_source -in @('exact-asset','reliable-built-in')) { 'ready' } elseif ($_.visual_source -eq 'approximate-built-in') { 'needs-review' } else { 'missing' }
    asset = $coverageAsset
    verification = Get-AssetVerificationStatus $_.english $coverageAsset
    edge_status = $coverageSafety.status
    required_asset = if ($_.visual_source -eq 'missing') { "$(Sanitize-Name $_.english).png" } else { '' }
    required_filename = if ($_.visual_source -eq 'missing') { "$(Sanitize-Name $_.english).png" } else { '' }
    category = Get-AssetCategory $_.english
    asset_prompt = Get-AssetPrompt $_.english $_.meaning
  }
})
$visualCoverageRows | Export-CsvForExcel -Path $visualCoveragePath
$visualMissingPromptPath = Join-Path $OutputDir 'visual-missing-prompts.txt'
if (Test-Path -LiteralPath $visualMissingPromptPath) { Remove-Item -LiteralPath $visualMissingPromptPath -Force }
Write-AssetPromptPack -Rows @($visualCoverageRows | Where-Object { $_.status -eq 'missing' }) -Path $visualMissingPromptPath

$assetSafetyReportPath = Join-Path $OutputDir 'asset-safety-report.csv'
$assetSafetyRows = @($taggedManifest |
  Where-Object { $_.type -in @('word','combo') } |
  Group-Object { "$($_.english)".ToLowerInvariant() } |
  ForEach-Object {
    $item = $_.Group[0]
    $asset = Resolve-IllustrationAsset $item.english
    $safety = Get-AssetSafety $asset
    [pscustomobject]@{
      english = $item.english
      meaning = $item.meaning
      asset = $asset
      verification = Get-AssetVerificationStatus $item.english $asset
      width = $safety.width
      height = $safety.height
      edge_hits = $safety.edge_hits
      edge_status = $safety.status
      note = $safety.note
    }
  })
$assetSafetyRows | Export-CsvForExcel -Path $assetSafetyReportPath
$assetSafetyLookup = @{}
foreach ($row in $assetSafetyRows) { $assetSafetyLookup[$row.english.ToLowerInvariant()] = $row }

$fulfillmentReportPath = Join-Path $OutputDir 'fulfillment-report.csv'
$requestedByType = [ordered]@{
  word = if ($Mode -in @('word','mixed')) { $WordCount } else { 0 }
  sentence = if ($Mode -in @('sentence','mixed')) { $SentenceCount } else { 0 }
  combo = if ($Mode -in @('combo','mixed')) { $ComboCount } else { 0 }
  lesson = if ($Mode -in @('lesson','mixed')) { $LessonCount } else { 0 }
}
$fulfillmentRows = @($requestedByType.Keys | ForEach-Object {
  $cardType = $_
  $requested = [int]$requestedByType[$cardType]
  $actual = @($taggedManifest | Where-Object { $_.type -eq $cardType }).Count
  [pscustomobject]@{
    type = $cardType
    requested = $requested
    generated = $actual
    status = if ($actual -eq $requested) { 'fulfilled' } elseif ($actual -lt $requested) { 'reduced-no-repeat' } else { 'over-generated' }
    note = if ($actual -lt $requested) { '内容库不足时已减少输出，未重复内容凑数' } else { '' }
  }
})
$fulfillmentRows | Export-CsvForExcel -Path $fulfillmentReportPath

$duplicateReportPath = Join-Path $OutputDir 'duplicate-report.csv'
$duplicateGroups = @($taggedManifest |
  Where-Object { $_.type -ne 'lesson' } |
  Group-Object { "$($_.type)|$("$($_.english)".Trim().ToLowerInvariant())" } |
  Where-Object { $_.Count -gt 1 })
$duplicateLookup = @{}
$duplicateRows = New-Object System.Collections.Generic.List[object]
foreach ($group in $duplicateGroups) {
  foreach ($item in $group.Group) {
    $key = "$($item.type)|$("$($item.english)".Trim().ToLowerInvariant())"
    $duplicateLookup[$key] = $group.Count
  }
  $sample = $group.Group[0]
  $duplicateRows.Add([pscustomobject]@{
    status = 'duplicate'
    type = $sample.type
    english = $sample.english
    count = $group.Count
    files = (($group.Group | ForEach-Object { Split-Path $_.file -Leaf }) -join '；')
  })
}
if ($duplicateRows.Count -eq 0) {
  $duplicateRows.Add([pscustomobject]@{
    status = 'pass'
    type = ''
    english = ''
    count = 0
    files = ''
  })
}
$duplicateRows | Export-CsvForExcel -Path $duplicateReportPath

$qualityReportPath = Join-Path $OutputDir 'quality-report.csv'
$qualityReport = @($taggedManifest | ForEach-Object {
  $issues = New-Object System.Collections.Generic.List[string]
  if (-not $_.english) { $issues.Add('缺少英文') }
  if (-not $_.phonetic) { $issues.Add('缺少音标') }
  if (-not $_.meaning) { $issues.Add('缺少中文意思') }
  if ($_.visual_source -eq 'missing') { $issues.Add("缺少对应图片：$($_.visual_cue)") }
  elseif ($_.visual_source -eq 'approximate-built-in') { $issues.Add("使用近似简图，请人工确认：$($_.visual_cue)") }
  $assetSafetyKey = "$($_.english)".ToLowerInvariant()
  if ($assetSafetyLookup.ContainsKey($assetSafetyKey) -and $assetSafetyLookup[$assetSafetyKey].edge_status -eq 'needs-review') {
    $issues.Add('配图靠近边缘，存在截断风险')
  }
  $duplicateKey = "$($_.type)|$("$($_.english)".Trim().ToLowerInvariant())"
  if ($duplicateLookup.ContainsKey($duplicateKey)) { $issues.Add("同类型内容重复 $($duplicateLookup[$duplicateKey]) 次") }
  if ($PhoneticPolicy -eq 'curated-only' -and $_.phonetic_source -match 'generated') { $issues.Add('严格音标模式下发现模板生成音标') }
  $textLength = "$($_.english)$($_.meaning)".Length
  if ($_.type -eq 'lesson' -and $textLength -gt 90) { $issues.Add('学习页文字较多，请预览确认行距') }
  $layoutScore = 100
  if ($_.type -eq 'lesson' -and $textLength -gt 90) { $layoutScore -= 25 }
  if ($_.visual_source -eq 'missing') { $layoutScore -= 35 }
  elseif ($_.visual_source -eq 'approximate-built-in') { $layoutScore -= 20 }
  elseif ($_.visual_source -eq 'reliable-built-in') { $layoutScore -= 5 }
  if ($assetSafetyLookup.ContainsKey($assetSafetyKey) -and $assetSafetyLookup[$assetSafetyKey].edge_status -eq 'needs-review') { $layoutScore -= 30 }
  if ("$($_.english)".Length -gt 36) { $layoutScore -= 15 }
  if ("$($_.meaning)".Length -gt 28) { $layoutScore -= 10 }
  if ($layoutScore -lt 0) { $layoutScore = 0 }
  $readability = if ($layoutScore -ge 85) { '适合手机和打印' } elseif ($layoutScore -ge 70) { '建议预览确认' } else { '需要调整排版' }
  $status = if ($issues.Count -eq 0) { 'pass' } elseif ($issues.Count -eq 1 -and $issues[0] -like '使用近似简图*') { 'pass-with-visual-check' } else { 'needs-check' }
  $grade = if ($issues | Where-Object { $_ -match '缺少英文|缺少音标|缺少中文意思' }) { 'D' } elseif ($status -eq 'needs-check') { 'C' } elseif ($status -eq 'pass-with-visual-check') { 'B' } else { 'A' }
  [pscustomobject]@{
    file = Split-Path $_.file -Leaf
    type = $_.type
    english = $_.english
    phonetic_source = $_.phonetic_source
    visual_cue = $_.visual_cue
    visual_source = $_.visual_source
    grade = $grade
    layout_score = $layoutScore
    readability = $readability
    status = $status
    issues = ($issues -join '；')
  }
})
$qualityReport | Export-CsvForExcel -Path $qualityReportPath

$activityPackPath = ''
$activityAnswerKeyPath = ''
$activityAnswerHtmlPath = ''
if ($ActivityPack) {
  $activityWords = @($words | Select-Object -First ([Math]::Min(8, $words.Count)))
  $activityPackPath = Join-Path $OutputDir 'activity-pack.csv'
  $activityAnswerKeyPath = Join-Path $OutputDir 'activity-answer-key.csv'
  $activityAnswerHtmlPath = Join-Path $OutputDir 'activity-answer-key.html'
  $activityRows = New-Object System.Collections.Generic.List[object]
  if ($activityWords.Count -ge 3) {
    $target = $activityWords[0]
    $activityRows.Add([pscustomobject]@{
      activity = '看图选单词'
      prompt = "请选择 $($target.meaning) 对应的英文。"
      answer = $target.english
      options = (($activityWords | Select-Object -First 3 | ForEach-Object { $_.english }) -join ' / ')
      parent_tip = '先让孩子看图，再读三个英文选项。'
    })
  }
  if ($activityWords.Count -ge 2) {
    $activityRows.Add([pscustomobject]@{
      activity = '中英连线'
      prompt = '把英文单词和中文意思连起来。'
      answer = (($activityWords | Select-Object -First 5 | ForEach-Object { "$($_.english)=$($_.meaning)" }) -join '；')
      options = ''
      parent_tip = '适合打印后用笔连线。'
    })
  }
  $activityRows.Add([pscustomobject]@{
    activity = '看中文说英文'
    prompt = '家长读中文，孩子说英文。'
    answer = (($activityWords | Select-Object -First 6 | ForEach-Object { "$($_.meaning)=$($_.english)" }) -join '；')
    options = ''
    parent_tip = '说不出时先看图，再看英文。'
  })
  $activityRows | Export-CsvForExcel -Path $activityPackPath
  $activityAnswerRows = @($activityRows | ForEach-Object {
    [pscustomobject]@{
      activity = $_.activity
      prompt = $_.prompt
      answer = $_.answer
      parent_tip = $_.parent_tip
    }
  })
  $activityAnswerRows | Export-CsvForExcel -Path $activityAnswerKeyPath
  Write-TableHtml -Rows $activityAnswerRows -Columns @('activity','prompt','answer','parent_tip') -Labels @{
    activity = '练习'
    prompt = '题目'
    answer = '答案'
    parent_tip = '家长提示'
  } -Title "$script:ThemeLabel 练习答案表" -Path $activityAnswerHtmlPath

  if ($ActivityImages) {
    $activityIndex = 1
    foreach ($activity in $activityRows) {
      $safeActivity = Sanitize-Name $activity.activity
      $activityFile = 'activity-{0:D3}-{1}.png' -f $activityIndex, $safeActivity
      $null = Save-Card $activityFile {
        param($g)
        $main = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104))
        $sub = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 38, 54, 74))
        $cn = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 216, 107, 92))
        Draw-CenteredText $g $activity.activity (New-Font 'Microsoft YaHei' 70 ([System.Drawing.FontStyle]::Bold)) $main 130 210 820 90
        Draw-CenteredText $g $activity.prompt (New-Font 'Microsoft YaHei' 46 ([System.Drawing.FontStyle]::Bold)) $sub 145 340 790 120
        if ($activity.activity -eq '看图选单词') {
          $targetWord = $activityWords[0]
          Draw-VisualCue $g $targetWord.meaning 340 475 400 300 $targetWord.english
          $options = @("$($activity.options)" -split '\s*/\s*')
          $y = 820
          $letters = @('A','B','C','D')
          for ($optionIndex = 0; $optionIndex -lt $options.Count; $optionIndex++) {
            $option = $options[$optionIndex]
            $label = "$($letters[$optionIndex]). $option"
            $optionBg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 234, 247, 255))
            Add-RoundedRect $g $optionBg 210 $y 660 90 28
            $optionBg.Dispose()
            Draw-CenteredText $g $label (New-Font 'Segoe UI' 42 ([System.Drawing.FontStyle]::Bold)) $main 230 ($y + 8) 620 70
            $y += 108
          }
        } elseif ($activity.activity -eq '中英连线') {
          $lineWords = @($activityWords | Select-Object -First 4)
          $lineTop = 485
          $lineBottom = 1160
          $lineGap = 15
          $lineCount = [Math]::Max(1, $lineWords.Count)
          $lineRowHeight = [Math]::Floor(($lineBottom - $lineTop - (($lineCount - 1) * $lineGap)) / $lineCount)
          $cueHeight = [Math]::Min(160, $lineRowHeight)
          $y = $lineTop
          foreach ($word in $lineWords) {
            Draw-VisualCue $g $word.meaning 150 $y 300 $cueHeight $word.english
            $lineCenterY = $y + [Math]::Floor($cueHeight / 2)
            Draw-CenteredText $g $word.english (New-Font 'Segoe UI' 40 ([System.Drawing.FontStyle]::Bold)) $main 625 ($lineCenterY - 36) 260 70
            $matchLine = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 180, 160, 218), 4)
            $g.DrawLine($matchLine, 470, $lineCenterY, 605, $lineCenterY)
            $matchLine.Dispose()
            $y += $lineRowHeight + $lineGap
          }
        } elseif ($activity.activity -eq '看中文说英文') {
          $gridWords = @($activityWords | Select-Object -First 6)
          for ($wordIndex = 0; $wordIndex -lt $gridWords.Count; $wordIndex++) {
            $word = $gridWords[$wordIndex]
            $col = $wordIndex % 2
            $row = [Math]::Floor($wordIndex / 2)
            $cueX = 170 + ($col * 390)
            $cueY = 485 + ($row * 245)
            Draw-VisualCue $g $word.meaning $cueX $cueY 350 215 $word.english
          }
        } elseif ($activity.options) {
          $options = @("$($activity.options)" -split '\s*/\s*')
          $y = 540
          foreach ($option in $options) {
            Draw-CenteredText $g $option (New-Font 'Segoe UI' 44 ([System.Drawing.FontStyle]::Bold)) $main 200 $y 680 80
            $y += 110
          }
        } else {
          Draw-CenteredText $g $activity.answer (New-Font 'Segoe UI' 42 ([System.Drawing.FontStyle]::Bold)) $main 145 560 790 260
        }
        Draw-CenteredText $g $activity.parent_tip (New-Font 'Microsoft YaHei' 34) $cn 145 1210 790 120
        $main.Dispose(); $sub.Dispose(); $cn.Dispose()
      }
      $activityIndex += 1
    }
  }
}

$phonicsPackPath = ''
if ($PhonicsPack) {
  $phonicsPackPath = Join-Path $OutputDir 'phonics-pack.csv'
  $phonicsRows = @($words | Select-Object -First ([Math]::Min(12, $words.Count)) | ForEach-Object {
    [pscustomobject]@{
      word = $_.english
      phonetic = $_.phonetic
      meaning = $_.meaning
      first_letter = if ($_.english) { $_.english.Substring(0, 1).ToUpperInvariant() } else { '' }
      phonics_focus = Get-PhonicsFocus $_.english
      practice = "Say the first sound, then say $($_.english)."
      parent_tip = "先读首字母音，再读完整单词。"
    }
  })
  $phonicsRows | Export-CsvForExcel -Path $phonicsPackPath
}

$learningRecordPath = ''
if ($LearningRecord) {
  $learningRecordPath = Join-Path $OutputDir 'learning-record.csv'
  $recordRows = @($taggedManifest | ForEach-Object {
    [pscustomobject]@{
      date = ''
      card = Split-Path $_.file -Leaf
      type = $_.type
      english = $_.english
      meaning = $_.meaning
      status = '未学'
      review_date = ''
      parent_note = ''
    }
  })
  $recordRows | Export-CsvForExcel -Path $learningRecordPath
}

$coursePlanPath = ''
$parentGuidePath = ''
if ($CoursePack) {
  $coursePlanPath = Join-Path $OutputDir 'course-plan.csv'
  $stepMap = @{
    'word' = '1 新词认读'
    'sentence' = '2 短句跟读'
    'combo' = '3 看图说句'
    'lesson' = '4 主题学习页'
  }
  $order = 1
  $coursePlan = @($taggedManifest | ForEach-Object {
    $day = [Math]::Min(7, [Math]::Max(1, [Math]::Ceiling($order / 5)))
    [pscustomobject]@{
      order = $order++
      day = $day
      step = $stepMap[$_.type]
      card_type = $_.type
      english = $_.english
      phonetic = $_.phonetic
      meaning = $_.meaning
      file = $_.file
    }
  })
  $coursePlan | Export-CsvForExcel -Path $coursePlanPath

  $parentGuidePath = Join-Path $OutputDir 'parent-guide.txt'
  $guide = @"
儿童英语课程包使用说明

主题：$script:ThemeLabel
阶段：$Stage
难度：$Difficulty

建议使用方式：
1. 先看单词卡，让孩子看图说中文意思。
2. 再读英文单词，家长可以带读 2-3 遍。
3. 看组合卡，让孩子把单词放进短句里说出来。
4. 最后看多句组合学习页，按顺序跟读。

每日建议：
- 低龄儿童每次 5-10 分钟即可。
- 一次不要学太多，优先保证孩子愿意开口。
- 第二天先复习旧卡，再看新卡。

检查重点：
- 图片是否能让孩子理解意思。
- 英文、音标、中文是否完整。
- 孩子是否能跟读其中 2-3 句。
"@
  Set-Content -LiteralPath $parentGuidePath -Value $guide -Encoding UTF8
}

$sevenDayPath = ''
$dailyParentGuidePath = ''
if ($SevenDayPack) {
  $sevenDayPath = Join-Path $OutputDir 'seven-day-learning-plan.csv'
  $dailyParentGuidePath = Join-Path $OutputDir 'daily-parent-guide.html'
  $wordFiles = @($taggedManifest | Where-Object { $_.type -eq 'word' } | Select-Object -ExpandProperty file | ForEach-Object { Split-Path $_ -Leaf })
  $sentenceFiles = @($taggedManifest | Where-Object { $_.type -eq 'sentence' } | Select-Object -ExpandProperty file | ForEach-Object { Split-Path $_ -Leaf })
  $comboFiles = @($taggedManifest | Where-Object { $_.type -eq 'combo' } | Select-Object -ExpandProperty file | ForEach-Object { Split-Path $_ -Leaf })
  $lessonFiles = @($taggedManifest | Where-Object { $_.type -eq 'lesson' } | Select-Object -ExpandProperty file | ForEach-Object { Split-Path $_ -Leaf })
  $JoinSome = {
    param($Items, [int]$Start, [int]$Count)
    if (-not $Items -or $Items.Count -eq 0) { return '' }
    return (@($Items | Select-Object -Skip $Start -First $Count) -join '；')
  }
  $dayPlan = @(
    [pscustomobject]@{ day = 1; focus = '看图认单词'; cards = (& $JoinSome $wordFiles 0 6); action = '先看图说中文，再听/读英文'; parent_question = '这是什么？Can you say it in English?'; review = '会读的画星，不会读的放到第2天复习' }
    [pscustomobject]@{ day = 2; focus = '音标和跟读'; cards = (& $JoinSome $wordFiles 0 8); action = '复习第1天单词，重点读英文和 IPA 音标'; parent_question = '这个单词第一个声音是什么？'; review = '每个单词跟读 3 遍' }
    [pscustomobject]@{ day = 3; focus = '短句输入'; cards = (& $JoinSome $sentenceFiles 0 5); action = '英文先读，中文后理解，再跟读'; parent_question = '这句话是什么意思？你能跟我读吗？'; review = '选2句最常用的重复说' }
    [pscustomobject]@{ day = 4; focus = '单词放进句子'; cards = (& $JoinSome $comboFiles 0 5); action = '使用组合卡，把单词和短句连起来读'; parent_question = '看图说一句完整英文。'; review = '能独立说出的句子标记为已会' }
    [pscustomobject]@{ day = 5; focus = '主题学习页'; cards = (& $JoinSome $lessonFiles 0 1); action = '学习1张多句组合页，按行跟读'; parent_question = '你最喜欢哪一句？再读一遍。'; review = '圈出最难的2句' }
    [pscustomobject]@{ day = 6; focus = '趣味复习'; cards = (& $JoinSome $wordFiles 0 5) + '；' + (& $JoinSome $comboFiles 0 3); action = '遮住英文，看图片和中文回忆英文'; parent_question = '不看英文，你能说出来吗？'; review = '把不会的卡片加入复习清单' }
    [pscustomobject]@{ day = 7; focus = '小测和奖励'; cards = '混合使用本周卡片和 activity-*.png'; action = '完成看图选词、连线、看中文说英文'; parent_question = '这周你学会了哪3个英文？'; review = '记录已会、半会、不会三类' }
  )
  $dayPlan | Export-CsvForExcel -Path $sevenDayPath
  Write-TableHtml -Rows $dayPlan -Columns @('day','focus','cards','action','parent_question','review') -Labels @{
    day = '天数'
    focus = '重点'
    cards = '使用卡片'
    action = '怎么带读'
    parent_question = '家长提问'
    review = '复习记录'
  } -Title "$script:ThemeLabel 7天亲子学习指南" -Path $dailyParentGuidePath
}

$qualityLookup = @{}
foreach ($qualityItem in $qualityReport) {
  $qualityLookup[$qualityItem.file] = $qualityItem
}
$qaCardsHtml = ($taggedManifest | ForEach-Object {
  $fileName = Split-Path $_.file -Leaf
  $qualityItem = $qualityLookup[$fileName]
  $qaStatus = if ($qualityItem) { $qualityItem.status } else { 'needs-check' }
  $qaGrade = if ($qualityItem) { $qualityItem.grade } else { 'C' }
  $qaIssues = if ($qualityItem -and $qualityItem.issues) { $qualityItem.issues } else { '未发现问题' }
  $statusLabel = if ($qaStatus -eq 'pass') { '通过' } elseif ($qaStatus -eq 'pass-with-visual-check') { '建议复查' } else { '需要检查' }
  @"
<article class="qa-card" data-status="$(Escape-Html $qaStatus)" data-type="$(Escape-Html $_.type)">
  <a href="./$(Escape-Html $fileName)" target="_blank"><img src="./$(Escape-Html $fileName)" alt="$(Escape-Html $_.english)"></a>
  <div class="qa-meta">
    <div class="qa-row"><strong>$(Escape-Html $_.english)</strong><span class="badge $qaStatus">$statusLabel · $qaGrade</span></div>
    <div class="muted">$(Escape-Html $_.type) · $(Escape-Html $_.meaning)</div>
    <div class="issues">$(Escape-Html $qaIssues)</div>
  </div>
</article>
"@
}) -join "`n"
$activityQaFiles = @(Get-ChildItem -LiteralPath $OutputDir -Filter 'activity-*.png' -File -ErrorAction SilentlyContinue)
if ($activityQaFiles.Count -gt 0) {
  $qaCardsHtml += "`n" + (($activityQaFiles | ForEach-Object {
    @"
<article class="qa-card" data-status="needs-check" data-type="activity">
  <a href="./$(Escape-Html $_.Name)" target="_blank"><img src="./$(Escape-Html $_.Name)" alt="互动练习页"></a>
  <div class="qa-meta">
    <div class="qa-row"><strong>互动练习页</strong><span class="badge needs-check">建议抽查 · C</span></div>
    <div class="muted">activity · $(Escape-Html $_.Name)</div>
    <div class="issues">请检查图片、选项、中文标签和底部提示是否完整且对应。</div>
  </div>
</article>
"@
  }) -join "`n")
}
$qaPassCount = @($qualityReport | Where-Object { $_.status -eq 'pass' }).Count
$qaReviewCount = @($qualityReport | Where-Object { $_.status -ne 'pass' }).Count + $activityQaFiles.Count
$qaSafeAssetCount = @($assetSafetyRows | Where-Object { $_.edge_status -eq 'safe' }).Count
$qaUnsafeAssetCount = @($assetSafetyRows | Where-Object { $_.edge_status -ne 'safe' }).Count
$qaFulfilledCount = @($fulfillmentRows | Where-Object { $_.status -eq 'fulfilled' }).Count
$qaReducedCount = @($fulfillmentRows | Where-Object { $_.status -ne 'fulfilled' }).Count
$qaDashboardPath = Join-Path $OutputDir 'qa-dashboard.html'
$qaDashboard = @"
<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>儿童英语学习卡质检总览</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f7f8f5;color:#26364a;font-family:Segoe UI,Microsoft YaHei,sans-serif}
header{background:#fff;padding:24px;border-bottom:1px solid #e7ebe7;position:sticky;top:0;z-index:2}
h1{margin:0 0 8px;font-size:28px;color:#1f5d68}.sub{margin:0;color:#627080}.wrap{max-width:1500px;margin:auto;padding:22px}
.summary{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px;margin-bottom:20px}
.metric{background:#fff;padding:16px;border:1px solid #e3e9e5;border-radius:8px}.metric b{display:block;font-size:27px;color:#1f5d68}.metric span{color:#627080;font-size:14px}
.tools{display:flex;flex-wrap:wrap;gap:8px;margin:0 0 18px}.tools button,.tools a{border:1px solid #cfdad4;background:#fff;color:#26364a;padding:9px 13px;border-radius:6px;text-decoration:none;cursor:pointer;font-size:14px}.tools button.active{background:#1f5d68;color:#fff;border-color:#1f5d68}
.qa-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));gap:16px}.qa-card{background:#fff;border:1px solid #e3e9e5;border-radius:8px;overflow:hidden}.qa-card img{width:100%;display:block;aspect-ratio:2/3;object-fit:contain;background:#fffaf0}.qa-meta{padding:12px}.qa-row{display:flex;align-items:center;justify-content:space-between;gap:8px}.muted{font-size:13px;color:#6d7885;margin-top:5px}.issues{font-size:13px;line-height:1.5;margin-top:8px;color:#9a4f42}.badge{white-space:nowrap;font-size:12px;padding:4px 7px;border-radius:4px;background:#fff0dc;color:#965c17}.badge.pass{background:#e4f5eb;color:#27734a}.badge.needs-check{background:#ffe9e5;color:#a33b30}
.hidden{display:none}@media(max-width:640px){header{position:static;padding:18px}.wrap{padding:14px}.qa-grid{grid-template-columns:repeat(2,minmax(0,1fr));gap:9px}.qa-meta{padding:8px}.qa-row{display:block}.issues{font-size:12px}}
</style>
<header><h1>儿童英语学习卡质检总览</h1><p class="sub">主题：$(Escape-Html $script:ThemeLabel)　阶段：$(Escape-Html $Stage)　共 $($taggedManifest.Count) 张</p></header>
<main class="wrap">
  <section class="summary">
    <div class="metric"><b>$qaPassCount</b><span>质量检查通过</span></div>
    <div class="metric"><b>$qaReviewCount</b><span>需要人工复查</span></div>
    <div class="metric"><b>$qaSafeAssetCount</b><span>配图边缘安全</span></div>
    <div class="metric"><b>$qaUnsafeAssetCount</b><span>配图截断风险</span></div>
    <div class="metric"><b>$qaFulfilledCount</b><span>数量完成类型</span></div>
    <div class="metric"><b>$qaReducedCount</b><span>数量减少类型</span></div>
  </section>
  <nav class="tools">
    <button class="active" data-filter="all">全部图片</button>
    <button data-filter="risk">只看问题</button>
    <button data-filter="word">单词卡</button>
    <button data-filter="combo">组合卡</button>
    <button data-filter="sentence">短句卡</button>
    <button data-filter="lesson">学习页</button>
    <button data-filter="activity">互动练习</button>
    <a href="./preflight-report.csv">生成前预检</a>
    <a href="./preflight-assets.csv">逐词配图检查</a>
    <a href="./asset-safety-report.csv">截断风险报告</a>
    <a href="./quality-report.csv">质量报告</a>
  </nav>
  <section class="qa-grid">$qaCardsHtml</section>
</main>
<script>
const buttons=[...document.querySelectorAll('button[data-filter]')],cards=[...document.querySelectorAll('.qa-card')];
buttons.forEach(button=>button.addEventListener('click',()=>{buttons.forEach(x=>x.classList.remove('active'));button.classList.add('active');const f=button.dataset.filter;cards.forEach(card=>{const show=f==='all'||(f==='risk'&&card.dataset.status!=='pass')||card.dataset.type===f;card.classList.toggle('hidden',!show)})}));
</script>
"@
Set-Content -LiteralPath $qaDashboardPath -Value $qaDashboard -Encoding UTF8

$cardsHtml = ($taggedManifest | ForEach-Object {
  $fileName = Split-Path $_.file -Leaf
  "<figure><img src='./$fileName' alt='$($_.english)'/><figcaption>$($_.type): $($_.english)<br/>$($_.system) / $($_.level) / $($_.difficulty)</figcaption></figure>"
}) -join "`n"

$coursePackHtml = ''
if ($CoursePack) {
  $coursePackHtml = "<p>课程包文件：<a href='./course-plan.csv'>course-plan.csv</a> | <a href='./parent-guide.txt'>parent-guide.txt</a></p>"
}

$supportFiles = New-Object System.Collections.Generic.List[string]
if ($SevenDayPack) {
  $supportFiles.Add("<a href='./seven-day-learning-plan.csv'>seven-day-learning-plan.csv</a>")
  $supportFiles.Add("<a href='./daily-parent-guide.html'>daily-parent-guide.html</a>")
}
if ($ActivityPack) {
  $supportFiles.Add("<a href='./activity-pack.csv'>activity-pack.csv</a>")
  $supportFiles.Add("<a href='./activity-answer-key.html'>activity-answer-key.html</a>")
}
if ($PhonicsPack) { $supportFiles.Add("<a href='./phonics-pack.csv'>phonics-pack.csv</a>") }
if ($LearningRecord) { $supportFiles.Add("<a href='./learning-record.csv'>learning-record.csv</a>") }
$supportFilesHtml = if ($supportFiles.Count -gt 0) { "<p>配套文件：$($supportFiles -join ' | ')</p>" } else { '' }
$downloadZipHtml = if ($ExportZip) { "<a class='primary' href='./english-learning-pack.zip'>下载完整 ZIP 包</a>" } else { "<span class='disabled'>本次未开启 ZIP 打包</span>" }
$parentUseZipHtml = if ($ExportZip) { "<a class='primary soft' href='./parent-use-pack.zip'>下载家长使用包</a>" } else { "" }

$printPath = ''
if ($PrintLayout) {
  $printPath = Join-Path $OutputDir 'print-a4.html'
  $perPage = [int]$CardsPerPrintPage
  $columns = if ($perPage -eq 6) { 3 } else { 2 }
  $printPages = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $taggedManifest.Count; $i += $perPage) {
    $end = [Math]::Min($i + $perPage - 1, $taggedManifest.Count - 1)
    $slice = @($taggedManifest[$i..$end])
    $items = ($slice | ForEach-Object {
      $fileName = Split-Path $_.file -Leaf
      "<figure><img src='./$fileName' alt='$($_.english)'/><figcaption>$($_.english)　$($_.meaning)</figcaption></figure>"
    }) -join "`n"
    $printPages.Add("<section class='sheet'>$items</section>")
  }
  $printHtml = @"
<!doctype html>
<meta charset="utf-8">
<title>English Learning Cards Print Layout</title>
<style>
@page{size:A4 portrait;margin:8mm}
body{margin:0;background:#f4f4f4;font-family:Segoe UI,Microsoft YaHei,sans-serif;color:#26364a}
.sheet{width:194mm;min-height:281mm;margin:0 auto 8mm;background:white;display:grid;grid-template-columns:repeat($columns,1fr);gap:5mm;box-sizing:border-box;padding:6mm;page-break-after:always}
figure{margin:0;break-inside:avoid}
img{width:100%;display:block;border:0.2mm solid #e8e2d7;border-radius:3mm}
figcaption{font-size:10pt;text-align:center;margin-top:2mm}
@media screen{body{padding:12px}.sheet{box-shadow:0 2px 18px rgba(0,0,0,.12)}}
</style>
$($printPages -join "`n")
"@
  Set-Content -LiteralPath $printPath -Value $printHtml -Encoding UTF8
}

$html = @"
<!doctype html>
<meta charset="utf-8">
<title>English Learning Cards Preview</title>
<style>
body{margin:0;padding:24px;font-family:Segoe UI,Microsoft YaHei,sans-serif;background:#fff7e8;color:#26364a}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:18px}
figure{margin:0;background:white;border-radius:10px;padding:10px;box-shadow:0 2px 14px rgba(0,0,0,.08)}
img{width:100%;display:block;border-radius:8px}
figcaption{font-size:14px;margin-top:8px}
</style>
<h1>English Learning Cards Preview</h1>
<p>体系: $System | 层级: $Level | 阶段: $Stage | 难度: $Difficulty | 模式: $Mode | 主题: $script:ThemeLabel | 视觉: $script:VisualStyle | 音标策略: $PhoneticPolicy</p>
$coursePackHtml
$supportFilesHtml
<p><strong><a href='./qa-dashboard.html'>打开中文可视化质检总览</a></strong></p>
<p><strong><a href='./download.html'>打开下载入口页</a></strong></p>
<p>检查文件：<a href='./preflight-report.csv'>preflight-report.csv</a> | <a href='./quality-report.csv'>quality-report.csv</a> | <a href='./visual-coverage.csv'>visual-coverage.csv</a> | <a href='./asset-safety-report.csv'>asset-safety-report.csv</a> | <a href='./duplicate-report.csv'>duplicate-report.csv</a> | <a href='./fulfillment-report.csv'>fulfillment-report.csv</a></p>
<div class="grid">
$cardsHtml
</div>
"@

Set-Content -LiteralPath (Join-Path $OutputDir 'preview.html') -Value $html -Encoding UTF8

$printLinkHtml = if ($PrintLayout) { '<a class="secondary" href="./print-a4.html">A4 打印</a>' } else { '' }
$printNavHtml = if ($PrintLayout) { '<a class="navcard" href="./print-a4.html"><strong>我要打印</strong><span>打开 A4 拼版，适合打印剪成卡片。</span></a>' } else { '' }
$printCommonFileHtml = if ($PrintLayout) { '<li><a href="./print-a4.html">A4 打印</a>：打印剪裁成实体卡片。</li>' } else { '' }

$parentGuideCardPath = Join-Path $OutputDir 'parent-guide-card.png'
$parentGuideCardName = Split-Path $parentGuideCardPath -Leaf
$null = Save-Card $parentGuideCardName {
  param($g)
  $main = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104))
  $sub = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 38, 54, 74))
  $accent = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 216, 107, 92))
  $muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 93, 112, 126))
  Draw-CenteredText $g '这套英语卡怎么用' (New-Font 'Microsoft YaHei' 66 ([System.Drawing.FontStyle]::Bold)) $main 130 180 820 95
  Draw-CenteredText $g "主题：$script:ThemeLabel" (New-Font 'Microsoft YaHei' 40 ([System.Drawing.FontStyle]::Bold)) $accent 150 292 780 68
  $steps = @(
    '1. 先打开「孩子互动学习」听英文。',
    '2. 每天学 5-10 分钟，不要求一次全背。',
    '3. 先看图说中文，再跟读英文和音标。',
    '4. 答错或读不出的内容，第二天先复习。',
    '5. 要打印时打开「A4 打印」。',
    '6. 想继续学习时查看「下一套建议」。'
  )
  $y = 410
  foreach ($step in $steps) {
    $boxBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 234, 247, 255))
    Add-RoundedRect $g $boxBrush 150 $y 780 116 28
    $boxBrush.Dispose()
    Draw-TextBox $g $step (New-Font 'Microsoft YaHei' 34 ([System.Drawing.FontStyle]::Bold)) $sub 190 ($y + 18) 700 82 ([System.Drawing.StringAlignment]::Near) ([System.Drawing.StringAlignment]::Center)
    $y += 125
  }
  Draw-CenteredText $g '家长提醒：少量多次，比一次学很多更有效。' (New-Font 'Microsoft YaHei' 34) $muted 155 1220 770 90
  Draw-CenteredText $g '先愿意开口，再慢慢读准。' (New-Font 'Microsoft YaHei' 32 ([System.Drawing.FontStyle]::Bold)) $accent 155 1320 770 80
  $main.Dispose(); $sub.Dispose(); $accent.Dispose(); $muted.Dispose()
}

$downloadPath = Join-Path $OutputDir 'download.html'
$typeSummaryHtml = ($taggedManifest | Group-Object type | Sort-Object Name | ForEach-Object {
  "<li><strong>$(Escape-Html (Convert-TypeLabel $_.Name))</strong>：$($_.Count) 张/页</li>"
}) -join "`n"
$qualitySummaryHtml = ($qualityReport | Group-Object status | Sort-Object Name | ForEach-Object {
  "<li><strong>$(Escape-Html (Convert-StatusLabel $_.Name))</strong>：$($_.Count)</li>"
}) -join "`n"
$firstCardsHtml = ($taggedManifest | Select-Object -First 6 | ForEach-Object {
  $fileName = Split-Path $_.file -Leaf
  "<a class='thumb' href='./$(Escape-Html $fileName)' target='_blank'><img src='./$(Escape-Html $fileName)' alt='$(Escape-Html $_.english)'><span>$(Escape-Html $_.english)</span></a>"
}) -join "`n"
$downloadHtml = @"
<!doctype html>
<meta charset="utf-8">
<title>儿童英语学习卡下载入口</title>
<style>
body{margin:0;background:#f7f1e7;color:#26364a;font-family:Segoe UI,Microsoft YaHei,sans-serif}
main{max-width:980px;margin:0 auto;padding:28px}
.hero{background:#fffdf8;border-radius:18px;padding:28px;box-shadow:0 6px 28px rgba(50,40,24,.08)}
h1{margin:0 0 12px;font-size:30px;color:#17636b}
.sub{margin:0;color:#526173;line-height:1.7}
.actions{display:flex;gap:12px;flex-wrap:wrap;margin:24px 0}
a{color:#17636b}
.primary,.secondary,.disabled{display:inline-block;border-radius:12px;padding:13px 18px;text-decoration:none;font-weight:700}
.primary{background:#17636b;color:white}
.soft{background:#d86558;color:white}
.secondary{background:#e5f3f4;color:#17636b}
.disabled{background:#eee2d3;color:#8a7660}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:14px;margin-top:18px}
.panel{background:white;border-radius:14px;padding:18px}
.navgrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:12px;margin-top:18px}
.navcard{display:block;background:white;border:1px solid #efe4d5;border-radius:14px;padding:16px;text-decoration:none;color:#26364a}
.navcard strong{display:block;color:#17636b;margin-bottom:6px;font-size:18px}.navcard span{font-size:14px;line-height:1.6;color:#68758a}
ul{margin:8px 0 0;padding-left:20px;line-height:1.9}
details{margin-top:18px;background:white;border-radius:14px;padding:16px}summary{cursor:pointer;font-weight:800;color:#17636b}
.thumbs{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:12px;margin-top:16px}
.thumb{background:white;border-radius:12px;padding:8px;text-align:center;text-decoration:none;color:#26364a}
.thumb img{width:100%;border-radius:10px;display:block}
.thumb span{display:block;margin-top:6px;font-size:13px}
.note{font-size:14px;color:#68758a;line-height:1.7}
</style>
<main>
  <section class="hero">
    <h1>儿童英语学习卡下载入口</h1>
    <p class="sub">主题：$(Escape-Html $script:ThemeLabel)　阶段：$(Escape-Html $Stage)　分级：$(Escape-Html $Level)　共 $($taggedManifest.Count) 张/页</p>
    <div class="actions">
      $parentUseZipHtml
      $downloadZipHtml
    </div>
    <div class="navgrid">
      <a class="secondary" href="./lesson-player.html">孩子互动学习</a>
      <a class="secondary" href="./today-learning-sheet.html">今日学习单</a>
      <a class="secondary" href="./parent-dashboard.html">家长进度页</a>
      <a class="secondary" href="./review-plan.html">复习安排</a>
      <a class="secondary" href="./parent-guide-card.png">家长说明卡</a>
      $printLinkHtml
      <a class="secondary" href="./usage-guide.txt">小白使用说明</a>
      <a class="secondary" href="./preview.html">预览全部卡片</a>
    </div>
    <div class="navgrid">
      <a class="navcard" href="./lesson-player.html"><strong>我要给孩子看</strong><span>打开点读和中文意思小测。</span></a>
      <a class="navcard" href="./today-learning-sheet.html"><strong>今天学什么</strong><span>按 5-10 分钟安排单词、短句和家长提问。</span></a>
      $printNavHtml
      <a class="navcard" href="./review-plan.html"><strong>我要复习</strong><span>按天安排复习，避免学完就忘。</span></a>
      <a class="navcard" href="./next-pack-suggestion.txt"><strong>下一套学什么</strong><span>继续生成同难度的新主题学习包。</span></a>
    </div>
    <p class="note">给家长或用户时，优先发送「家长使用包」或这个下载入口；完整 ZIP 包保留了全部质检和素材检查文件。</p>
  </section>
  <section class="grid">
    <div class="panel">
      <h2>内容数量</h2>
      <ul>$typeSummaryHtml</ul>
    </div>
    <div class="panel">
      <h2>质量状态</h2>
      <ul>$qualitySummaryHtml</ul>
    </div>
    <div class="panel">
      <h2>家长常用文件</h2>
      <ul>
        <li><a href="./today-learning-sheet.html">今日学习单</a>：告诉家长今天先学哪几张、怎么提问。</li>
        <li><a href="./lesson-player.html">孩子互动学习</a>：听英文、跟读、做小测。</li>
        <li><a href="./parent-guide-card.png">家长说明卡</a>：一张图说明怎么带孩子学。</li>
        $printCommonFileHtml
        <li><a href="./review-plan.html">复习安排</a>：按天复习不会的内容。</li>
      </ul>
    </div>
  </section>
  <details>
    <summary>高级检查文件</summary>
    <ul>
      <li><a href="./quality-report.csv">质量报告</a>：检查英文、音标、中文、排版和问题项。</li>
      <li><a href="./visual-coverage.csv">配图检查表</a>：查看每个单词是否有对应配图、是否缺图。</li>
      <li><a href="./fulfillment-report.csv">数量完成表</a>：对比请求数量和实际生成数量。</li>
      <li><a href="./qa-dashboard.html">质检总览</a>：筛选查看需要复查的图片。</li>
      <li><a href="./content-gap-report.csv">内容缺口报告</a>：查看缺少配图、数量不足和质量复查建议。</li>
      <li><a href="./creator-next-actions.txt">制作者下一步建议</a>：告诉制作者下一步先补什么。</li>
      <li><a href="./manifest.csv">内容清单</a>：查看全部英文、音标、中文和文件路径。</li>
      <li><a href="./bundle-summary.txt">学习包摘要</a>：查看主题、阶段、文件清单和质量等级说明。</li>
    </ul>
  </details>
  <section>
    <h2>快速预览</h2>
    <div class="thumbs">$firstCardsHtml</div>
  </section>
</main>
"@
Set-Content -LiteralPath $downloadPath -Value $downloadHtml -Encoding UTF8

$lessonPlayerPath = Join-Path $OutputDir 'lesson-player.html'
$playerItems = @($taggedManifest | Where-Object { $_.type -in @('word','sentence','combo') } | Select-Object -First 60 | ForEach-Object {
  [pscustomobject]@{
    type = $_.type
    english = $_.english
    phonetic = $_.phonetic
    meaning = $_.meaning
    image = Split-Path $_.file -Leaf
  }
})
if ($playerItems.Count -eq 0) {
  $playerItems = @($taggedManifest | Select-Object -First 20 | ForEach-Object {
    [pscustomobject]@{
      type = $_.type
      english = $_.english
      phonetic = $_.phonetic
      meaning = $_.meaning
      image = Split-Path $_.file -Leaf
    }
  })
}
$playerItemsJson = ($playerItems | ConvertTo-Json -Depth 5 -Compress)
$lessonPlayerHtml = @"
<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>儿童英语互动学习页</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f4fbf8;color:#24364a;font-family:Segoe UI,Microsoft YaHei,sans-serif}
main{max-width:980px;margin:auto;padding:22px}.top{display:flex;justify-content:space-between;gap:12px;align-items:center;margin-bottom:14px}
h1{margin:0;color:#17636b;font-size:26px}.pill{background:#fff;border:1px solid #dce9e4;border-radius:999px;padding:8px 12px;color:#55716f}
.stage{background:white;border:1px solid #dce9e4;border-radius:20px;padding:20px;box-shadow:0 8px 28px rgba(28,78,76,.08)}
.card{display:grid;grid-template-columns:minmax(240px,42%) 1fr;gap:22px;align-items:center}.card img{width:100%;border-radius:16px;background:#fff7e8;border:1px solid #edf0ea}
.en{font-size:42px;font-weight:800;color:#17636b;line-height:1.15}.ipa{font-size:22px;color:#7c6798;margin-top:10px}.cn{font-size:28px;color:#e06d5f;margin-top:14px}
.actions{display:flex;flex-wrap:wrap;gap:10px;margin-top:22px}button,a.button{border:0;border-radius:12px;padding:12px 16px;background:#17636b;color:white;font-weight:700;text-decoration:none;cursor:pointer}.light{background:#e6f4f0;color:#17636b}.warm{background:#f4b860;color:#553800}
.quiz{margin-top:20px;background:#fffdf8;border-radius:16px;padding:16px}.quiz h2{margin:0 0 12px;font-size:20px}.options{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.options button{background:#f0f6ff;color:#24364a}.options button.ok{background:#c9efd8}.options button.bad{background:#ffd8d1}
.progress{height:10px;background:#dce9e4;border-radius:99px;overflow:hidden;margin:12px 0 0}.bar{height:100%;width:0;background:#65bfa9}
@media(max-width:720px){main{padding:14px}.top{display:block}.card{grid-template-columns:1fr}.en{font-size:34px}.cn{font-size:24px}.options{grid-template-columns:1fr}}
</style>
<main>
  <div class="top"><h1>孩子互动学习页</h1><span class="pill">主题：$(Escape-Html $script:ThemeLabel)</span></div>
  <section class="stage">
    <div class="card">
      <img id="cardImage" src="" alt="">
      <div>
        <div class="pill" id="cardType"></div>
        <div class="en" id="english"></div>
        <div class="ipa" id="phonetic"></div>
        <div class="cn" id="meaning"></div>
        <div class="actions">
          <button onclick="speakCurrent()">听英文</button>
          <button class="light" onclick="prevCard()">上一张</button>
          <button class="light" onclick="nextCard()">下一张</button>
          <a class="button warm" href="./download.html">返回下载入口</a>
        </div>
      </div>
    </div>
    <div class="progress"><div class="bar" id="bar"></div></div>
    <section class="quiz">
      <h2>小测：这句/这个词是什么意思？</h2>
      <div class="options" id="options"></div>
    </section>
  </section>
</main>
<script>
const items=$playerItemsJson;
let index=0, answered=0;
const byId=id=>document.getElementById(id);
function optionSet(item){
  const meanings=[...new Set(items.map(x=>x.meaning).filter(Boolean))];
  const wrong=meanings.filter(x=>x!==item.meaning).sort(()=>0.5-Math.random()).slice(0,3);
  return [...wrong,item.meaning].sort(()=>0.5-Math.random());
}
function render(){
  const item=items[index]||{};
  byId('cardImage').src=item.image||'';
  byId('cardImage').alt=item.english||'';
  byId('cardType').textContent=(index+1)+' / '+items.length+' · '+(item.type||'card');
  byId('english').textContent=item.english||'';
  byId('phonetic').textContent=item.phonetic||'';
  byId('meaning').textContent=item.meaning||'';
  byId('bar').style.width=((index+1)/Math.max(1,items.length)*100)+'%';
  const box=byId('options'); box.innerHTML='';
  optionSet(item).forEach(text=>{const b=document.createElement('button');b.textContent=text;b.onclick=()=>{if(text===item.meaning){b.className='ok';answered++}else{b.className='bad'}};box.appendChild(b)});
}
function speakCurrent(){const text=(items[index]||{}).english||''; if(!text||!('speechSynthesis' in window)) return; const u=new SpeechSynthesisUtterance(text); u.lang='en-US'; u.rate=.82; speechSynthesis.cancel(); speechSynthesis.speak(u)}
function nextCard(){index=(index+1)%items.length;render()}
function prevCard(){index=(index-1+items.length)%items.length;render()}
render();
</script>
"@
Set-Content -LiteralPath $lessonPlayerPath -Value $lessonPlayerHtml -Encoding UTF8

$parentDashboardPath = Join-Path $OutputDir 'parent-dashboard.html'
$typeMetrics = ($taggedManifest | Group-Object type | Sort-Object Name | ForEach-Object {
  "<li><strong>$(Escape-Html (Convert-TypeLabel $_.Name))</strong>：$($_.Count)</li>"
}) -join "`n"
$qualityMetrics = ($qualityReport | Group-Object grade | Sort-Object Name | ForEach-Object {
  "<li><strong>等级 $(Escape-Html $_.Name)</strong>：$($_.Count)</li>"
}) -join "`n"
$fulfillmentMetrics = ($fulfillmentRows | ForEach-Object {
  "<tr><td>$(Escape-Html (Convert-TypeLabel $_.type))</td><td>$($_.requested)</td><td>$($_.generated)</td><td>$(Escape-Html (Convert-StatusLabel $_.status))</td></tr>"
}) -join "`n"
$todayList = ($taggedManifest | Where-Object { $_.type -in @('word','combo','sentence') } | Select-Object -First 8 | ForEach-Object {
  "<li><strong>$(Escape-Html $_.english)</strong> <span>$(Escape-Html $_.phonetic)</span><br><em>$(Escape-Html $_.meaning)</em></li>"
}) -join "`n"
$reviewTips = if ($LearningRecord) { '已生成 learning-record.csv，家长可填写未学、半会、已会后重新生成个性化复习计划。' } else { '如需记录掌握度，下次生成时加入 -LearningRecord。' }
$parentDashboardHtml = @"
<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>家长学习进度页</title>
<style>
body{margin:0;background:#fbf7ef;color:#26364a;font-family:Segoe UI,Microsoft YaHei,sans-serif}main{max-width:1060px;margin:auto;padding:24px}
h1{margin:0 0 8px;color:#17636b}.sub{color:#647386;line-height:1.7}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:14px}.panel{background:white;border-radius:16px;padding:18px;border:1px solid #ece2d4}
.metric{font-size:34px;font-weight:800;color:#17636b}.actions{display:flex;gap:10px;flex-wrap:wrap;margin:16px 0 22px}a{color:#17636b}a.button{background:#17636b;color:white;text-decoration:none;border-radius:12px;padding:12px 16px;font-weight:700}.light{background:#e5f3f4!important;color:#17636b!important}
ul{padding-left:20px;line-height:1.9}li span{color:#7c6798}li em{color:#d86558;font-style:normal}table{width:100%;border-collapse:collapse;margin-top:10px}td,th{border-bottom:1px solid #ece2d4;padding:9px;text-align:left}.plan li{margin-bottom:8px}
</style>
<main>
  <h1>家长学习进度页</h1>
  <p class="sub">主题：$(Escape-Html $script:ThemeLabel)　阶段：$(Escape-Html $Stage)　难度：$(Escape-Html $Difficulty)　共 $($taggedManifest.Count) 张/页。这个页面给家长看，用来判断今天学什么、质量是否可用、后续怎么复习。</p>
  <div class="actions">
    <a class="button" href="./lesson-player.html">打开孩子互动学习页</a>
    <a class="button light" href="./download.html">返回下载入口</a>
    <a class="button light" href="./qa-dashboard.html">查看质检</a>
  </div>
  <section class="grid">
    <div class="panel"><div class="metric">$($taggedManifest.Count)</div><p>总卡片/页面</p><ul>$typeMetrics</ul></div>
    <div class="panel"><div class="metric">$qaPassCount</div><p>质量通过项</p><ul>$qualityMetrics</ul></div>
    <div class="panel"><div class="metric">$qaReviewCount</div><p>待人工复查项</p><p>$reviewTips</p></div>
  </section>
  <section class="grid" style="margin-top:14px">
    <div class="panel">
      <h2>今日建议学习</h2>
      <ol class="plan">
        <li>先打开互动学习页，点「听英文」跟读。</li>
        <li>学习下面 6-8 个重点内容，不要求一次全背。</li>
        <li>用小测选中文意思，答错的标记为「半会」。</li>
      </ol>
      <ul>$todayList</ul>
    </div>
    <div class="panel">
      <h2>数量完成情况</h2>
      <table><thead><tr><th>类型</th><th>请求</th><th>生成</th><th>状态</th></tr></thead><tbody>$fulfillmentMetrics</tbody></table>
    </div>
  </section>
</main>
"@
Set-Content -LiteralPath $parentDashboardPath -Value $parentDashboardHtml -Encoding UTF8

$todayLearningSheetPath = Join-Path $OutputDir 'today-learning-sheet.html'
$todayWords = @($taggedManifest | Where-Object { $_.type -eq 'word' } | Select-Object -First 4)
$todaySentences = @($taggedManifest | Where-Object { $_.type -in @('sentence','combo') } | Select-Object -First 4)
if (($todayWords.Count + $todaySentences.Count) -eq 0) {
  $todayWords = @($taggedManifest | Select-Object -First 4)
}
$todayWordHtml = ($todayWords | ForEach-Object {
  $fileName = Split-Path $_.file -Leaf
  "<article><img src='./$(Escape-Html $fileName)' alt='$(Escape-Html $_.english)'><b>$(Escape-Html $_.english)</b><span>$(Escape-Html $_.phonetic)</span><em>$(Escape-Html $_.meaning)</em></article>"
}) -join "`n"
$todaySentenceHtml = ($todaySentences | ForEach-Object {
  "<li><strong>$(Escape-Html $_.english)</strong><span>$(Escape-Html $_.phonetic)</span><em>$(Escape-Html $_.meaning)</em></li>"
}) -join "`n"
if (-not $todaySentenceHtml) { $todaySentenceHtml = '<li><strong>看图说英文</strong><span>先认图，再跟读。</span><em>家长先读中文，孩子尝试说英文。</em></li>' }
$todayLearningSheetHtml = @"
<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>今日学习单</title>
<style>
body{margin:0;background:#f7f1e7;color:#26364a;font-family:Segoe UI,Microsoft YaHei,sans-serif}main{max-width:980px;margin:auto;padding:24px}
h1{margin:0 0 8px;color:#17636b}.sub{color:#647386;line-height:1.7}.steps{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:12px;margin:18px 0}
.step,.panel,article{background:white;border:1px solid #ece2d4;border-radius:16px;padding:16px}.step b{display:block;color:#17636b;margin-bottom:6px}
.words{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px}.words img{width:100%;aspect-ratio:1.15/1;object-fit:contain;background:#eef9fb;border-radius:12px}.words b{display:block;font-size:22px;color:#17636b;margin-top:8px}.words span,li span{display:block;color:#7c6798;margin-top:4px}.words em,li em{display:block;color:#d86558;font-style:normal;margin-top:4px}
ul{padding-left:20px;line-height:1.9}li{margin-bottom:10px}.actions{display:flex;gap:10px;flex-wrap:wrap;margin-top:18px}a{color:#17636b}.button{background:#17636b;color:white;text-decoration:none;border-radius:12px;padding:12px 16px;font-weight:700}.light{background:#e5f3f4;color:#17636b}
@media print{body{background:white}main{padding:10mm}.actions{display:none}.step,.panel,article{break-inside:avoid}}
</style>
<main>
  <h1>今日学习单</h1>
  <p class="sub">主题：$(Escape-Html $script:ThemeLabel)　阶段：$(Escape-Html $Stage)。适合家长每天拿出来用，5-10 分钟即可。</p>
  <section class="steps">
    <div class="step"><b>1 看图</b>家长先问中文：“这是什么？”不要急着要求孩子读英文。</div>
    <div class="step"><b>2 听英文</b>打开互动页点「听英文」，孩子跟读 1-2 遍。</div>
    <div class="step"><b>3 说中文</b>孩子说出中文意思，确认理解，不要只背声音。</div>
    <div class="step"><b>4 小复习</b>不会的标记为“半会”，明天先复习。</div>
  </section>
  <section class="panel">
    <h2>今天先学这些单词</h2>
    <div class="words">$todayWordHtml</div>
  </section>
  <section class="panel" style="margin-top:14px">
    <h2>今天跟读这些短句</h2>
    <ul>$todaySentenceHtml</ul>
  </section>
  <section class="panel" style="margin-top:14px">
    <h2>家长今天只问 3 个问题</h2>
    <ul>
      <li>这张图是什么？你能说英文吗？</li>
      <li>这个英文是什么意思？</li>
      <li>你最喜欢哪一张？再读一遍。</li>
    </ul>
  </section>
  <div class="actions">
    <a class="button" href="./lesson-player.html">打开互动学习页</a>
    <a class="button light" href="./review-plan.html">打开复习安排</a>
    <a class="button light" href="./download.html">返回下载入口</a>
  </div>
</main>
"@
Set-Content -LiteralPath $todayLearningSheetPath -Value $todayLearningSheetHtml -Encoding UTF8

$contentGapReportPath = Join-Path $OutputDir 'content-gap-report.csv'
$contentGapRows = New-Object System.Collections.Generic.List[object]
foreach ($row in $fulfillmentRows) {
  if ($row.generated -lt $row.requested) {
    $contentGapRows.Add([pscustomobject]@{
      gap_type = '数量不足'
      priority = '高'
      type = $row.type
      target = "$($row.requested - $row.generated) 个"
      problem = "请求 $($row.requested)，实际生成 $($row.generated)"
      suggested_action = '补充同阶段同主题内容，或降低请求数量；不要重复内容凑数。'
    })
  }
}
foreach ($row in @($visualCoverageRows | Where-Object { $_.status -eq 'missing' } | Select-Object -First 30)) {
  $contentGapRows.Add([pscustomobject]@{
    gap_type = '缺少配图'
    priority = '高'
    type = 'word'
    target = $row.english
    problem = "缺少对应图片：$($row.expected_visual)"
    suggested_action = "按 $($row.required_filename) 补充正式图片，或临时换成已有可靠配图的单词。"
  })
}
foreach ($row in @($qualityReport | Where-Object { $_.status -ne 'pass' } | Select-Object -First 30)) {
  $contentGapRows.Add([pscustomobject]@{
    gap_type = '质量复查'
    priority = if ($row.grade -in @('C','D')) { '高' } else { '中' }
    type = $row.type
    target = $row.english
    problem = $row.issues
    suggested_action = '打开 qa-dashboard.html 查看对应图片，优先修复错图、缺字段、截断和重复。'
  })
}
if ($contentGapRows.Count -eq 0) {
  $contentGapRows.Add([pscustomobject]@{
    gap_type = '无明显缺口'
    priority = '低'
    type = 'all'
    target = $script:ThemeLabel
    problem = '本次数量、字段和配图检查未发现必须阻断的问题。'
    suggested_action = '可继续生成相邻主题，或扩大同阶段内容库。'
  })
}
$contentGapRows | Export-CsvForExcel -Path $contentGapReportPath

$creatorNextActionsPath = Join-Path $OutputDir 'creator-next-actions.txt'
$topGaps = @($contentGapRows | Select-Object -First 8 | ForEach-Object {
  "- [$($_.priority)] $($_.gap_type)：$($_.target)；$($_.suggested_action)"
}) -join "`r`n"
$creatorNextActions = @"
制作者下一步优化建议

本次主题：$script:ThemeLabel
本次阶段：$Stage

优先处理顺序：
1. 先看 content-gap-report.csv，处理高优先级缺口。
2. 再看 qa-dashboard.html，只修复需要复查的图片和卡片。
3. 如果缺图，优先补 assets/illustrations 中的正式图片。
4. 如果数量不足，优先扩充同主题内容库，不要重复凑数。
5. 如果给家长分发，优先发送 parent-use-pack.zip。

本次自动发现：
$topGaps
"@
Set-Content -LiteralPath $creatorNextActionsPath -Value $creatorNextActions -Encoding UTF8

$usageGuidePath = Join-Path $OutputDir 'usage-guide.txt'
$usageGuide = @"
儿童英语学习包小白使用说明

第一步：打开 download.html。
这是整个学习包的入口，可以下载 ZIP、预览图片、打开孩子互动学习页和家长进度页。

第二步：先给孩子看 lesson-player.html。
点击「听英文」，让孩子先听，再跟读。不会读没关系，先让孩子愿意开口。

第三步：不知道今天学什么时，打开 today-learning-sheet.html。
它会列出今天优先学习的单词、短句和家长提问方式。

第四步：每天只学 5-10 分钟。
低龄孩子不要一次学太多，优先选 6-8 张单词卡或组合卡。

第五步：用 review-plan.html 复习。
当天学新内容，第二天先复习旧内容。不会的内容写进 learning-record.csv。

第六步：想继续生成下一套时，看 next-pack-suggestion.txt。
里面会给出更适合继续学习的主题和一键预设名称。
"@
Set-Content -LiteralPath $usageGuidePath -Value $usageGuide -Encoding UTF8

$reviewPlanPath = Join-Path $OutputDir 'review-plan.html'
$reviewItems = @($taggedManifest | Where-Object { $_.type -in @('word','sentence','combo') } | Select-Object -First 12)
$reviewRowsHtml = ($reviewItems | ForEach-Object {
  "<tr><td>$(Escape-Html $_.english)</td><td>$(Escape-Html $_.phonetic)</td><td>$(Escape-Html $_.meaning)</td><td>未学 / 半会 / 已会</td></tr>"
}) -join "`n"
$reviewPlanHtml = @"
<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>儿童英语复习安排</title>
<style>
body{margin:0;background:#fbf7ef;color:#26364a;font-family:Segoe UI,Microsoft YaHei,sans-serif}main{max-width:980px;margin:auto;padding:24px}
h1{margin:0 0 8px;color:#17636b}.sub{color:#647386;line-height:1.7}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:14px;margin:18px 0}
.panel{background:white;border:1px solid #ece2d4;border-radius:16px;padding:18px}b{color:#17636b}ol,ul{line-height:1.9}table{width:100%;border-collapse:collapse;background:white;border-radius:16px;overflow:hidden}th,td{padding:10px;border-bottom:1px solid #ece2d4;text-align:left}a{color:#17636b}
</style>
<main>
  <h1>儿童英语复习安排</h1>
  <p class="sub">主题：$(Escape-Html $script:ThemeLabel)　阶段：$(Escape-Html $Stage)。这个页面给家长用，重点不是一次学完，而是每天一点点复现。</p>
  <section class="grid">
    <div class="panel"><b>第 1 天</b><p>看图认词，跟读英文。每个内容读 2 遍即可。</p></div>
    <div class="panel"><b>第 2 天</b><p>先复习第 1 天不会的，再学新卡。答错的标记为半会。</p></div>
    <div class="panel"><b>第 4 天</b><p>遮住中文，让孩子先猜意思；再打开互动页点读。</p></div>
    <div class="panel"><b>第 7 天</b><p>只复习半会和不会的内容，已会内容不用反复刷。</p></div>
  </section>
  <h2>优先复习清单</h2>
  <table><thead><tr><th>英文</th><th>音标</th><th>中文</th><th>掌握情况</th></tr></thead><tbody>$reviewRowsHtml</tbody></table>
  <p><a href="./lesson-player.html">打开孩子互动学习页</a>　<a href="./parent-dashboard.html">打开家长进度页</a>　<a href="./download.html">返回下载入口</a></p>
</main>
"@
Set-Content -LiteralPath $reviewPlanPath -Value $reviewPlanHtml -Encoding UTF8

$nextPackSuggestionPath = Join-Path $OutputDir 'next-pack-suggestion.txt'
$nextPresetMap = @{
  'classroom' = @('grade1-family','grade1-weather','grade1-park')
  'zoo-animals' = @('grade1-classroom','grade1-breakfast','grade1-weather')
  'breakfast' = @('grade1-family','grade1-classroom','grade1-park')
  'family' = @('grade1-breakfast','grade1-weather','grade1-classroom')
  'weather' = @('grade1-park','grade1-classroom','grade1-family')
  'park-play' = @('grade1-animals','grade1-weather','grade1-family')
  'cleaning-room' = @('grade1-classroom','grade1-family','grade1-breakfast')
  'bedtime' = @('preschool-family','preschool-breakfast','kindergarten-classroom')
  'general' = @('preschool-animals','grade1-classroom','grade1-family')
}
$suggestedPresets = if ($nextPresetMap.ContainsKey($themeKey)) { $nextPresetMap[$themeKey] } else { @('grade1-classroom','grade1-animals','grade1-family') }
$nextPackText = @"
下一套学习包建议

本次主题：$script:ThemeLabel
本次阶段：$Stage

建议下一步不要立刻提高难度，先换一个生活场景继续练同等难度内容。

可直接使用的一键预设：
1. $($suggestedPresets[0])
2. $($suggestedPresets[1])
3. $($suggestedPresets[2])

复制示例：
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -Preset $($suggestedPresets[0]) -OutputDir .\output\next-pack

给小白用户的话术：
继续生成下一套同难度学习包，主题换成 $($suggestedPresets[0])，并导出 ZIP、互动学习页和复习安排。
"@
Set-Content -LiteralPath $nextPackSuggestionPath -Value $nextPackText -Encoding UTF8

$bundleSummaryPath = Join-Path $OutputDir 'bundle-summary.txt'
$optionalFiles = New-Object System.Collections.Generic.List[string]
foreach ($freeFile in @('usage-guide.txt','review-plan.html','today-learning-sheet.html','next-pack-suggestion.txt','parent-guide-card.png','content-gap-report.csv','creator-next-actions.txt')) {
  $optionalFiles.Add($freeFile)
}
if ($PrintLayout) { $optionalFiles.Add('print-a4.html') }
if ($CoursePack) { $optionalFiles.Add('course-plan.csv') }
if ($CoursePack) { $optionalFiles.Add('parent-guide.txt') }
if ($SevenDayPack) { $optionalFiles.Add('seven-day-learning-plan.csv') }
if ($SevenDayPack) { $optionalFiles.Add('daily-parent-guide.html') }
if ($ActivityPack) { $optionalFiles.Add('activity-pack.csv') }
if ($ActivityPack) { $optionalFiles.Add('activity-answer-key.csv') }
if ($ActivityPack) { $optionalFiles.Add('activity-answer-key.html') }
if ($ActivityImages) { $optionalFiles.Add('activity-*.png') }
if ($PhonicsPack) { $optionalFiles.Add('phonics-pack.csv') }
if ($LearningRecord) { $optionalFiles.Add('learning-record.csv') }
if ($ExportZip) { $optionalFiles.Add('parent-use-pack.zip') }
if ($ExportZip) { $optionalFiles.Add('english-learning-pack.zip') }
$optionalFilesText = if ($optionalFiles.Count -gt 0) {
  ($optionalFiles | ForEach-Object { "- $_" }) -join "`r`n"
} else {
  '- 无'
}
@"
儿童英语学习包输出摘要

主题：$($script:ThemeLabel)
体系：$System
分级：$Level
阶段：$Stage
难度：$Difficulty
模式：$Mode
预设：$(if ($Preset) { $Preset } else { '未使用' })
音标策略：$PhoneticPolicy
卡片数量：$($taggedManifest.Count)

核心文件：
- manifest.csv
- preflight-report.csv
- preflight-assets.csv
- quality-report.csv
- visual-coverage.csv
- asset-safety-report.csv
- visual-missing-prompts.txt（仅缺图时生成）
- excluded-visuals.csv（仅有单词因缺少可靠配图被排除时生成）
- excluded-visual-prompts.txt（仅有排除项时生成）
- duplicate-report.csv
- fulfillment-report.csv
- preview.html
- download.html
- lesson-player.html
- today-learning-sheet.html
- parent-dashboard.html
- review-plan.html
- usage-guide.txt
- next-pack-suggestion.txt
- parent-guide-card.png
- qa-dashboard.html
- content-gap-report.csv
- creator-next-actions.txt
- recommended-themes.csv

可选文件：
$optionalFilesText

质量等级：
A = 字段完整
B = 字段完整，但建议人工确认配图
C = 需要检查排版或内容
D = 缺少关键字段
"@ | Set-Content -LiteralPath $bundleSummaryPath -Encoding UTF8

$parentUseZipPath = ''
if ($ExportZip) {
  $parentUseZipPath = Join-Path $OutputDir 'parent-use-pack.zip'
  if (Test-Path -LiteralPath $parentUseZipPath) { Remove-Item -LiteralPath $parentUseZipPath -Force }
  $parentUseNames = New-Object System.Collections.Generic.List[string]
  foreach ($name in @(
    'download.html',
    'lesson-player.html',
    'today-learning-sheet.html',
    'parent-dashboard.html',
    'review-plan.html',
    'usage-guide.txt',
    'next-pack-suggestion.txt',
    'parent-guide-card.png',
    'preview.html',
    'daily-parent-guide.html',
    'activity-answer-key.html',
    'parent-guide.txt',
    'learning-record.csv'
  )) {
    $candidate = Join-Path $OutputDir $name
    if (Test-Path -LiteralPath $candidate) { $parentUseNames.Add($candidate) }
  }
  foreach ($pattern in @('word-*.png','sentence-*.png','combo-*.png','lesson-*.png','activity-*.png')) {
    foreach ($file in @(Get-ChildItem -LiteralPath $OutputDir -Filter $pattern -File -ErrorAction SilentlyContinue)) {
      $parentUseNames.Add($file.FullName)
    }
  }
  if ($PrintLayout -and $printPath -and (Test-Path -LiteralPath $printPath)) { $parentUseNames.Add($printPath) }
  if ($parentUseNames.Count -gt 0) {
    $dedupedParentUse = @($parentUseNames | Select-Object -Unique)
    Compress-Archive -LiteralPath $dedupedParentUse -DestinationPath $parentUseZipPath -Force
  }
}

$zipPath = ''
if ($ExportZip) {
  $zipPath = Join-Path $OutputDir 'english-learning-pack.zip'
  if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
  $filesToZip = Get-ChildItem -LiteralPath $OutputDir -File | Where-Object { $_.FullName -ne $zipPath }
  if ($filesToZip) {
    Compress-Archive -LiteralPath ($filesToZip | ForEach-Object { $_.FullName }) -DestinationPath $zipPath -Force
  }
}

Write-Output "Generated $($taggedManifest.Count) cards."
Write-Output "Output: $OutputDir"
Write-Output "Manifest: $manifestPath"
Write-Output "Preflight report: $preflightReportPath"
Write-Output "Preflight assets: $preflightAssetsPath"
Write-Output "Quality report: $qualityReportPath"
Write-Output "Visual coverage: $visualCoveragePath"
Write-Output "Asset safety report: $assetSafetyReportPath"
if (Test-Path -LiteralPath $visualMissingPromptPath) {
  Write-Output "Visual missing prompts: $visualMissingPromptPath"
}
if (Test-Path -LiteralPath $excludedVisualsPath) {
  Write-Output "Excluded visuals: $excludedVisualsPath"
  Write-Output "Excluded visual prompts: $excludedVisualPromptsPath"
}
Write-Output "Duplicate report: $duplicateReportPath"
Write-Output "Fulfillment report: $fulfillmentReportPath"
Write-Output "Preview: $(Join-Path $OutputDir 'preview.html')"
Write-Output "Download page: $downloadPath"
Write-Output "Lesson player: $lessonPlayerPath"
Write-Output "Today learning sheet: $todayLearningSheetPath"
Write-Output "Parent dashboard: $parentDashboardPath"
Write-Output "Review plan: $reviewPlanPath"
Write-Output "Usage guide: $usageGuidePath"
Write-Output "Next pack suggestion: $nextPackSuggestionPath"
Write-Output "Parent guide card: $parentGuideCardPath"
Write-Output "QA dashboard: $qaDashboardPath"
Write-Output "Content gap report: $contentGapReportPath"
Write-Output "Creator next actions: $creatorNextActionsPath"
Write-Output "Bundle summary: $bundleSummaryPath"
if ($PrintLayout) {
  Write-Output "Print layout: $printPath"
}
if ($CoursePack) {
  Write-Output "Course plan: $coursePlanPath"
  Write-Output "Parent guide: $parentGuidePath"
}
if ($SevenDayPack) {
  Write-Output "Seven-day learning plan: $sevenDayPath"
  Write-Output "Daily parent guide: $dailyParentGuidePath"
}
if ($ActivityPack) {
  Write-Output "Activity pack: $activityPackPath"
  Write-Output "Activity answer key: $activityAnswerKeyPath"
  Write-Output "Activity answer HTML: $activityAnswerHtmlPath"
}
if ($PhonicsPack) {
  Write-Output "Phonics pack: $phonicsPackPath"
}
if ($LearningRecord) {
  Write-Output "Learning record: $learningRecordPath"
}
if ($ExportZip) {
  Write-Output "Parent use zip: $parentUseZipPath"
  Write-Output "Zip: $zipPath"
}

