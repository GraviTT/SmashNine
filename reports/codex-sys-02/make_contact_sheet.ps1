# Assemble actual Godot captures; this does not generate or alter game art.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$items = @(
    @('01-title', 'TITLE'),
    @('02-select-frey', 'CHARACTER SELECT / FREY'),
    @('03-select-nova-female', 'CHARACTER SELECT / NOVA FEMALE'),
    @('04-options', 'OPTIONS'),
    @('05-controls', 'CONTROLS'),
    @('06-results', 'RESULTS / FLOW TEST')
)
$board = New-Object System.Drawing.Bitmap 1280,1194
$graphics = [System.Drawing.Graphics]::FromImage($board)
$font = New-Object System.Drawing.Font 'Segoe UI',15,([System.Drawing.FontStyle]::Bold)
$brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(243,205,124))
try {
    $graphics.Clear([System.Drawing.Color]::FromArgb(10,15,27))
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    for ($i = 0; $i -lt $items.Count; $i++) {
        $x = ($i % 2) * 640
        $y = [Math]::Floor($i / 2) * 398
        $graphics.DrawString($items[$i][1],$font,$brush,$x + 12,$y + 6)
        $sourceImage = [System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($items[$i][0] + '.png')))
        try {
            $graphics.DrawImage($sourceImage,[System.Drawing.Rectangle]::new($x,$y + 34,640,360))
        } finally {
            $sourceImage.Dispose()
        }
    }
    $board.Save((Join-Path $PSScriptRoot 'contact-sheet.png'),[System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $brush.Dispose()
    $font.Dispose()
    $graphics.Dispose()
    $board.Dispose()
}
