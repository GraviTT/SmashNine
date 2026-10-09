param([Parameter(Mandatory=$true)][string]$OutDir,[Parameter(Mandatory=$true)][string]$FinalPath)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing

function New-Canvas([int]$w,[int]$h,[System.Drawing.Color]$color){$b=New-Object System.Drawing.Bitmap($w,$h,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($b);$g.Clear($color);return @($b,$g)}
function Save-Canvas($pair,[string]$path){$pair[0].Save($path,[System.Drawing.Imaging.ImageFormat]::Png);$pair[1].Dispose();$pair[0].Dispose()}

$bg=[System.Drawing.Color]::FromArgb(255,247,248,251)
$contact=New-Canvas 3060 1450 ([System.Drawing.Color]::FromArgb(255,233,237,245));$cg=$contact[1];$cg.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$variants=@('variant-a.png','variant-b.png','variant-c.png');$cropX=@(80,790,1920);$cropY=@(1140,1120,690)
for($i=0;$i -lt 3;$i++){$img=[System.Drawing.Image]::FromFile((Join-Path $OutDir $variants[$i]));$left=60+$i*990;$cg.DrawImage($img,(New-Object System.Drawing.Rectangle($left,28,960,700)),0,0,$img.Width,$img.Height,[System.Drawing.GraphicsUnit]::Pixel);$cg.DrawImage($img,(New-Object System.Drawing.Rectangle($left,754,960,675)),$cropX[$i],$cropY[$i],960,675,[System.Drawing.GraphicsUnit]::Pixel);$img.Dispose()}
Save-Canvas $contact (Join-Path $OutDir 'contact.png')

$final=[System.Drawing.Image]::FromFile($FinalPath)
$half=New-Canvas 1920 1400 $bg;$half[1].InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;$half[1].DrawImage($final,0,0,1920,1400);Save-Canvas $half (Join-Path $OutDir 'chosen-50.png')
$crop=New-Canvas 1600 1000 $bg;$crop[1].DrawImage($final,(New-Object System.Drawing.Rectangle(0,0,1600,1000)),1880,620,1600,1000,[System.Drawing.GraphicsUnit]::Pixel);Save-Canvas $crop (Join-Path $OutDir 'chosen-100-crop.png')
$final.Dispose()
