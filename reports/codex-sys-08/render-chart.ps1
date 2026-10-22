$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$rows = Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'chart-data.json') | ConvertFrom-Json
$bmp = [Drawing.Bitmap]::new(1100,570)
$g = [Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([Drawing.ColorTranslator]::FromHtml('#111827'))
$white = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#e5e7eb'))
$grey = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#6b7280'))
$blue = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#38bdf8'))
$title = [Drawing.Font]::new('Arial',24,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel)
$label = [Drawing.Font]::new('Arial',16,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel)
$small = [Drawing.Font]::new('Arial',14,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel)
$g.DrawString('SYS-08 | observed changes',$title,$white,30,14)
$g.DrawString('Before (QA-22): gray / After: blue. Rates are free-voice, direct-stream ceilings.',$small,$white,30,46)
for ($i=0; $i -lt $rows.Count; $i++) {
    $row = $rows[$i]
    $y = [single](90 + $i*70)
    $beforeWidth = [single]([double]$row[1] / [double]$row[3] * 470)
    $afterWidth = [single]([double]$row[2] / [double]$row[3] * 470)
    $g.DrawString([string]$row[0],$label,$white,30,[single]($y+4))
    $g.FillRectangle($grey,[single]480,$y,$beforeWidth,[single]19)
    $g.DrawString([string]$row[1],$small,$white,[single](490+$beforeWidth),$y)
    $g.FillRectangle($blue,[single]480,[single]($y+23),$afterWidth,[single]19)
    $g.DrawString([string]$row[2],$small,$white,[single](490+$afterWidth),[single]($y+23))
}
$g.DrawString('Headless measurements. No shipped sound assets. See README.md for assumptions and exact seed tables.',$small,$white,30,540)
$bmp.Save((Join-Path $PSScriptRoot 'comparison.png'),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
foreach ($item in @($white,$grey,$blue,$title,$label,$small)) { $item.Dispose() }
Write-Output 'SYS08 chart rendered from measured comparison data.'
