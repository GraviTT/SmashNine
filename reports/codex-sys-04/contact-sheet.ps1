param([string]$ReportDir = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$items = @(
    @('00-stage-five-overview-ko.png', '05장 · 붕괴 경고 / 수정 3개 · 전체 보기'),
    @('02-stage-seven-boss-ko.png', '07장 · 거대 마그마 멧돼지 / 보스 HP'),
    @('03-stage-nine-rivals-ko.png', '09장 1차전 · 네 라이벌 그림자의 난투'),
    @('04-stage-nine-shadow-dialogue-ko.png', '09장 중간 장면 · 내 그림자와 대화'),
    @('05-stage-nine-band-ko.png', '09장 2차전 · 축소 띠 / 자신의 그림자'),
    @('06-story-ending-ko.png', '엔딩 · 주인공 일러스트 / 대사 3줄')
)
$width = 640
$height = 360
$caption = 40
$gap = 12
$sheet = New-Object Drawing.Bitmap (2 * $width + 3 * $gap), (3 * ($height + $caption) + 4 * $gap)
$graphics = [Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([Drawing.Color]::FromArgb(13, 20, 33))
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = New-Object Drawing.Font 'Malgun Gothic', 18, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
$brush = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(240, 214, 158))
for ($index = 0; $index -lt $items.Count; $index++) {
    $x = $gap + ($index % 2) * ($width + $gap)
    $y = $gap + [Math]::Floor($index / 2) * ($height + $caption + $gap)
    $picture = [Drawing.Image]::FromFile((Join-Path $ReportDir $items[$index][0]))
    $graphics.DrawImage($picture, [Drawing.Rectangle]::new($x, $y, $width, $height))
    $graphics.DrawString($items[$index][1], $font, $brush, [single]($x + 7), [single]($y + $height + 9))
    $picture.Dispose()
}
$sheet.Save((Join-Path $ReportDir 'contact-sheet.png'), [Drawing.Imaging.ImageFormat]::Png)
$brush.Dispose()
$font.Dispose()
$graphics.Dispose()
$sheet.Dispose()
Write-Output 'Saved contact-sheet.png (six actual Korean Godot captures)'
