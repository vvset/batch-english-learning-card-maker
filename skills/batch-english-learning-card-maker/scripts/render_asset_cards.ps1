#requires -Version 7.0

param(
  [Parameter(Mandatory = $true)]
  [string]$InputCsv,

  [string]$OutputDir = '',

  [string]$AssetDir = '',

  [ValidateSet('word','sentence','combo','lesson','auto')]
  [string]$DefaultType = 'auto',

  [ValidateSet('png','jpg')]
  [string]$Format = 'png',

  [double]$AssetHeightRatio = 0.28
)

$ErrorActionPreference = 'Stop'
$SkillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
if (-not $OutputDir) { $OutputDir = Join-Path (Get-Location) 'output\asset-learning-cards' }
if (-not $AssetDir) { $AssetDir = Join-Path $SkillRoot 'assets\illustrations' }
New-Item -ItemType Directory -Force $OutputDir | Out-Null

Add-Type -AssemblyName System.Drawing

function New-Font {
  param([string]$Name, [float]$Size, [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular)
  try { return [System.Drawing.Font]::new($Name, $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel) }
  catch { return [System.Drawing.Font]::new('Arial', $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel) }
}

function Sanitize-Name {
  param([string]$Text)
  $value = "$Text".ToLowerInvariant() -replace '[^a-z0-9]+','-'
  $value = $value.Trim('-')
  if (-not $value) { $value = 'card' }
  return $value
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
    [System.Drawing.StringAlignment]$Align = [System.Drawing.StringAlignment]::Center
  )
  $format = [System.Drawing.StringFormat]::new()
  $format.Alignment = $Align
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $format.Trimming = [System.Drawing.StringTrimming]::Word
  $rect = [System.Drawing.RectangleF]::new($X, $Y, $W, $H)
  $G.DrawString($Text, $Font, $Brush, $rect, $format)
  $format.Dispose()
}

function Resolve-AssetPath {
  param($Row)
  if ($Row.PSObject.Properties.Name -contains 'asset' -and $Row.asset) {
    if (Test-Path -LiteralPath $Row.asset) { return (Resolve-Path -LiteralPath $Row.asset).Path }
    $fromDir = Join-Path $AssetDir $Row.asset
    if (Test-Path -LiteralPath $fromDir) { return (Resolve-Path -LiteralPath $fromDir).Path }
  }
  $safe = Sanitize-Name $Row.english
  foreach ($ext in @('png','jpg','jpeg','webp')) {
    $candidate = Join-Path $AssetDir "$safe.$ext"
    if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
  }
  return ''
}

function Draw-PageBase {
  param([System.Drawing.Graphics]$G, [int]$Width, [int]$Height)
  $bg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 248, 232))
  $panel = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 255, 250))
  $G.FillRectangle($bg, 0, 0, $Width, $Height)
  Add-RoundedRect $G $panel 96 96 ($Width - 192) ($Height - 192) 54
  $bg.Dispose(); $panel.Dispose()
}

function Draw-AssetContained {
  param(
    [System.Drawing.Graphics]$G,
    [string]$AssetPath,
    [int]$CanvasW,
    [int]$CanvasH,
    [double]$HeightRatio
  )
  $img = [System.Drawing.Image]::FromFile($AssetPath)
  $maxH = $CanvasH * $HeightRatio
  $maxW = $CanvasW * 0.58
  $scale = [Math]::Min($maxW / $img.Width, $maxH / $img.Height)
  $drawW = $img.Width * $scale
  $drawH = $img.Height * $scale
  $drawX = ($CanvasW - $drawW) / 2
  $drawY = $CanvasH * 0.105
  $G.DrawImage($img, $drawX, $drawY, $drawW, $drawH)
  $img.Dispose()
  return [pscustomobject]@{
    x = [Math]::Round($drawX, 1)
    y = [Math]::Round($drawY, 1)
    width = [Math]::Round($drawW, 1)
    height = [Math]::Round($drawH, 1)
    height_ratio = [Math]::Round($drawH / $CanvasH, 3)
  }
}

function Get-CardType {
  param($Row)
  if ($Row.PSObject.Properties.Name -contains 'type' -and $Row.type) { return "$($Row.type)" }
  if ($DefaultType -ne 'auto') { return $DefaultType }
  if ($Row.PSObject.Properties.Name -contains 'sentences' -and $Row.sentences) { return 'lesson' }
  if ($Row.PSObject.Properties.Name -contains 'example' -and $Row.example) { return 'word' }
  return 'sentence'
}

$rows = @(Import-Csv -LiteralPath $InputCsv)
if (-not $rows) { throw "No rows found in $InputCsv." }

$audit = New-Object System.Collections.Generic.List[object]
$manifest = New-Object System.Collections.Generic.List[object]

$main = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 31, 93, 104))
$navy = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 38, 54, 74))
$ipaBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 125, 106, 159))
$cnBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 216, 107, 92))

for ($i = 0; $i -lt $rows.Count; $i++) {
  $row = $rows[$i]
  $type = Get-CardType $row
  $asset = Resolve-AssetPath $row
  $safe = Sanitize-Name "$($row.english)"
  $name = '{0}-{1:D3}-{2}.{3}' -f $type, ($i + 1), $safe, $Format
  $outPath = Join-Path $OutputDir $name
  $issues = New-Object System.Collections.Generic.List[string]

  if (-not $row.english) { $issues.Add('缺少英文') }
  if (-not $row.phonetic -and $type -ne 'lesson') { $issues.Add('缺少音标') }
  if (-not $row.meaning) { $issues.Add('缺少中文意思') }
  if (-not $asset) { $issues.Add('缺少固定素材图') }

  if (-not $asset) {
    $audit.Add([pscustomobject]@{
      file = $name
      english = $row.english
      meaning = $row.meaning
      asset = ''
      asset_height_ratio = ''
      status = 'needs-asset'
      issues = ($issues -join '；')
    })
    continue
  }

  $bmp = [System.Drawing.Bitmap]::new(1080, 1620)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  Draw-PageBase $g 1080 1620
  $assetMetrics = Draw-AssetContained $g $asset 1080 1620 $AssetHeightRatio
  if ($assetMetrics.height_ratio -gt 0.31) { $issues.Add('素材占比偏大') }
  if ($assetMetrics.height_ratio -lt 0.18) { $issues.Add('素材占比偏小') }

  if ($type -eq 'word') {
    Draw-TextBox $g $row.english (New-Font 'Segoe UI' 126 ([System.Drawing.FontStyle]::Bold)) $main 130 740 820 135
    Draw-TextBox $g $row.phonetic (New-Font 'Segoe UI' 52) $ipaBrush 130 880 820 72
    Draw-TextBox $g $row.meaning (New-Font 'Microsoft YaHei' 72 ([System.Drawing.FontStyle]::Bold)) $cnBrush 130 965 820 88
    if ($row.PSObject.Properties.Name -contains 'example' -and $row.example) {
      Draw-TextBox $g $row.example (New-Font 'Segoe UI' 44 ([System.Drawing.FontStyle]::Bold)) $navy 130 1160 820 70
      Draw-TextBox $g $row.example_meaning (New-Font 'Microsoft YaHei' 38) $cnBrush 130 1230 820 64
    }
  } elseif ($type -eq 'combo') {
    Draw-TextBox $g $row.english (New-Font 'Segoe UI' 104 ([System.Drawing.FontStyle]::Bold)) $main 130 700 820 120
    Draw-TextBox $g $row.phonetic (New-Font 'Segoe UI' 48) $ipaBrush 130 825 820 68
    Draw-TextBox $g $row.meaning (New-Font 'Microsoft YaHei' 68 ([System.Drawing.FontStyle]::Bold)) $cnBrush 130 905 820 88
    if ($row.PSObject.Properties.Name -contains 'example' -and $row.example) {
      Draw-TextBox $g $row.example (New-Font 'Segoe UI' 50 ([System.Drawing.FontStyle]::Bold)) $navy 130 1120 820 74
      Draw-TextBox $g $row.example_meaning (New-Font 'Microsoft YaHei' 42) $cnBrush 130 1195 820 68
    }
  } elseif ($type -eq 'lesson') {
    Draw-TextBox $g $row.meaning (New-Font 'Microsoft YaHei' 56 ([System.Drawing.FontStyle]::Bold)) $main 120 500 840 76
    $items = @("$($row.sentences)" -split '\s*\|\s*' | Where-Object { $_ })
    $y = 630
    foreach ($item in $items[0..([Math]::Min(5, $items.Count - 1))]) {
      $parts = @($item -split '::')
      $en = $parts[0]
      $cn = if ($parts.Count -gt 1) { $parts[1] } else { '' }
      Draw-TextBox $g $en (New-Font 'Segoe UI' 39 ([System.Drawing.FontStyle]::Bold)) $navy 130 $y 820 50
      Draw-TextBox $g $cn (New-Font 'Microsoft YaHei' 31) $cnBrush 130 ($y + 45) 820 44
      $y += 115
    }
  } else {
    Draw-TextBox $g $row.english (New-Font 'Segoe UI' 72 ([System.Drawing.FontStyle]::Bold)) $main 120 760 840 140
    Draw-TextBox $g $row.phonetic (New-Font 'Segoe UI' 42) $ipaBrush 120 910 840 68
    Draw-TextBox $g $row.meaning (New-Font 'Microsoft YaHei' 64 ([System.Drawing.FontStyle]::Bold)) $cnBrush 120 1010 840 90
    if ($row.PSObject.Properties.Name -contains 'prompt' -and $row.prompt) {
      Draw-TextBox $g $row.prompt (New-Font 'Microsoft YaHei' 36 ([System.Drawing.FontStyle]::Bold)) $navy 140 1210 800 66
    }
  }

  if ($Format -eq 'jpg') { $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Jpeg) }
  else { $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png) }
  $g.Dispose(); $bmp.Dispose()

  $status = if ($issues.Count -eq 0) { 'pass' } else { 'needs-check' }
  $audit.Add([pscustomobject]@{
    file = $name
    english = $row.english
    meaning = $row.meaning
    asset = $asset
    asset_height_ratio = $assetMetrics.height_ratio
    status = $status
    issues = ($issues -join '；')
  })
  $manifest.Add([pscustomobject]@{
    type = $type
    english = $row.english
    phonetic = $row.phonetic
    meaning = $row.meaning
    asset = $asset
    file = $outPath
  })
}

$manifest | Export-Csv -LiteralPath (Join-Path $OutputDir 'manifest.csv') -NoTypeInformation -Encoding UTF8
$audit | Export-Csv -LiteralPath (Join-Path $OutputDir 'visual-audit.csv') -NoTypeInformation -Encoding UTF8

$main.Dispose(); $navy.Dispose(); $ipaBrush.Dispose(); $cnBrush.Dispose()

Write-Output "Output: $OutputDir"
Write-Output "Manifest: $(Join-Path $OutputDir 'manifest.csv')"
Write-Output "Visual audit: $(Join-Path $OutputDir 'visual-audit.csv')"
