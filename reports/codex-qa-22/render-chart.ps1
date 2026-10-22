$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$runs = Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'sound-summary.json') | ConvertFrom-Json
$run = $runs | Where-Object { $_.file -eq 'sound-br-1001.json' }
$rows = @($run.seconds)
$yMax = [Math]::Ceiling(($rows | Measure-Object -Property watched -Maximum).Maximum / 5) * 5
$xMax = $rows.Count
$bmp = [Drawing.Bitmap]::new(1100,420)
$g = [Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([Drawing.ColorTranslator]::FromHtml('#111827'))
$white = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#e5e7eb'))
$grey = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#9ca3af'))
$grid = [Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#374151'))
$line = [Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#38bdf8'),1.5)
$title = [Drawing.Font]::new('Arial',15,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel)
$small = [Drawing.Font]::new('Arial',12,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel)
$g.DrawString('QA-22 | 8 bots, seed 1001 | watched-realm requests / match second',$title,$white,65,15)
$g.DrawString('Measured request demand before missing assets, 40 ms gap and voice caps. Actual audio plays: 0.',$small,$grey,65,40)
for ($n=0; $n -le $yMax; $n+=5) {
 $y = [single](365 - $n / $yMax * 300)
 $g.DrawLine($grid,[single]65,$y,[single]1075,$y)
 $g.DrawString([string]$n,$small,$white,[single]38,[single]($y-7))
}
for ($t=0; $t -le $xMax; $t+=30) {
 $x = [single](65 + $t / $xMax * 1010)
 $g.DrawString("$($t)s",$small,$white,[single]($x-10),[single]379)
}
$points = [Drawing.PointF[]]@($rows | ForEach-Object {
 [Drawing.PointF]::new([single](65 + $_.second / $xMax * 1010),[single](365 - $_.watched / $yMax * 300))
})
$g.DrawLines($line,$points)
$g.DrawString('Aligned bins [s, s+1); zero-request seconds included. Source: sound-summary.json.',$small,$white,65,402)
$bmp.Save((Join-Path $PSScriptRoot 'sound-requests.png'),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
foreach ($item in @($white,$grey,$grid,$line,$title,$small)) { $item.Dispose() }
Write-Output 'Chart PNG rendered from the measured second buckets.'
