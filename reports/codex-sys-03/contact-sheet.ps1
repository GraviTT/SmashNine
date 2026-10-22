param([string]$ReportDir = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$items = @(
    @('01-title-ko.png', '01  타이틀 · 배틀로얄 / 스토리'),
    @('02-story-select-ko.png', '02  주인공 · 진행도 / 난이도'),
    @('03-story-map-ko.png', '03  아홉 렐름 지도'),
    @('04-stage-start-ko.png', '04  스테이지 시작 카드'),
    @('15-dialogue-hero-ko.png', '05  대화 · 화자 초상 / 색'),
    @('06-stage-one-ko.png', '06  1장 · 몬스터 목표'),
    @('07-stage-two-rival-ko.png', '07  2장 · 라이벌 체력'),
    @('08-stage-result-ko.png', '08  결과 · 시간 / 피해 / 카드'),
    @('09-pause-ko.png', '09  일시정지 · 네 가지 경로')
)
$width = 426
$height = 240
$caption = 34
$gap = 8
$sheet = New-Object System.Drawing.Bitmap (3 * $width + 4 * $gap), (3 * ($height + $caption) + 4 * $gap)
$graphics = [Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([Drawing.Color]::FromArgb(13, 20, 33))
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = New-Object Drawing.Font 'Malgun Gothic', 14, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
$brush = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(240, 214, 158))
for ($index = 0; $index -lt $items.Count; $index++) {
    $x = $gap + ($index % 3) * ($width + $gap)
    $y = $gap + [Math]::Floor($index / 3) * ($height + $caption + $gap)
    $image = [Drawing.Image]::FromFile((Join-Path $ReportDir $items[$index][0]))
    $graphics.DrawImage($image, [Drawing.Rectangle]::new($x, $y, $width, $height))
    $graphics.DrawString($items[$index][1], $font, $brush, [single]($x + 6), [single]($y + $height + 7))
    $image.Dispose()
}
$sheet.Save((Join-Path $ReportDir 'contact-sheet.png'), [Drawing.Imaging.ImageFormat]::Png)
$brush.Dispose()
$font.Dispose()
$graphics.Dispose()
$sheet.Dispose()
Write-Output 'Saved contact-sheet.png (nine real Korean captures)'
