param(
	[Parameter(Mandatory=$true)][string]$SvgPath,
	[Parameter(Mandatory=$true)][string]$PngPath
)

$ErrorActionPreference = 'Stop'
trap { Write-Error $_.InvocationInfo.PositionMessage; Write-Error $_.ScriptStackTrace; break }
Add-Type -AssemblyName System.Drawing

function Color-FromHex([string]$hex, [double]$opacity = 1.0) {
	if ($hex -eq 'none' -or [string]::IsNullOrWhiteSpace($hex)) { return [System.Drawing.Color]::Transparent }
	if ($hex.StartsWith('#')) {
		$r = [Convert]::ToInt32($hex.Substring(1,2),16)
		$g = [Convert]::ToInt32($hex.Substring(3,2),16)
		$b = [Convert]::ToInt32($hex.Substring(5,2),16)
		$a = [Math]::Max(0,[Math]::Min(255,[Math]::Round(255 * $opacity)))
		return [System.Drawing.Color]::FromArgb($a,$r,$g,$b)
	}
	return [System.Drawing.Color]::Transparent
}

function Rounded-Path([float]$x,[float]$y,[float]$w,[float]$h,[float]$r) {
	$p = New-Object System.Drawing.Drawing2D.GraphicsPath
	$r = [Math]::Min($r,[Math]::Min($w,$h)/2)
	$d = $r * 2
	if ($r -le 0) { $p.AddRectangle([System.Drawing.RectangleF]::new($x,$y,$w,$h)); return $p }
	$p.AddArc($x,$y,$d,$d,180,90)
	$p.AddArc($x+$w-$d,$y,$d,$d,270,90)
	$p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90)
	$p.AddArc($x,$y+$h-$d,$d,$d,90,90)
	$p.CloseFigure()
	return $p
}

function Draw-PathData($g,[string]$d,[System.Drawing.Pen]$pen) {
	$tokens = [regex]::Matches($d,'[MLHVmlhv]|-?\d+(?:\.\d+)?') | ForEach-Object { $_.Value }
	$points = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
	$i=0; $cmd=''; [float]$cx=0; [float]$cy=0
	while($i -lt $tokens.Count) {
		$t=$tokens[$i]
		if($t -match '^[MLHVmlhv]$'){ $cmd=$t; $i++; continue }
		switch -Regex ($cmd) {
			'^[MLml]$' { [float]$x=$tokens[$i]; [float]$y=$tokens[$i+1]; $i+=2; $cx=$x; $cy=$y; [void]$points.Add([System.Drawing.PointF]::new($cx,$cy)); if($cmd -match '[Mm]'){$cmd='L'} }
			'^[Hh]$' { [float]$cx=$tokens[$i]; $i++; [void]$points.Add([System.Drawing.PointF]::new($cx,$cy)) }
			'^[Vv]$' { [float]$cy=$tokens[$i]; $i++; [void]$points.Add([System.Drawing.PointF]::new($cx,$cy)) }
			default { $i++ }
		}
	}
	if($points.Count -ge 2){ $g.DrawLines($pen,$points.ToArray()) }
}

[xml]$svg = Get-Content -Raw -Encoding UTF8 $SvgPath
$root = $svg.DocumentElement
$width = [int][double]$root.GetAttribute('width')
$height = [int][double]$root.GetAttribute('height')
$bitmap = New-Object System.Drawing.Bitmap($width,$height,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bitmap)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.Clear([System.Drawing.Color]::FromArgb(255,247,248,251))

function Draw-Element($node) {
	if($node.NodeType -ne [System.Xml.XmlNodeType]::Element){ return }
	$name=$node.LocalName
	if($name -eq 'defs'){ return }
	if($name -eq 'g' -or $name -eq 'svg') { foreach($child in $node.ChildNodes){ Draw-Element $child }; return }
	if($name -eq 'rect') {
		[float]$x=$node.GetAttribute('x'); [float]$y=$node.GetAttribute('y'); [float]$w=$node.GetAttribute('width'); [float]$h=$node.GetAttribute('height')
		[float]$r=0; if($node.HasAttribute('rx')){$r=$node.GetAttribute('rx')}
		$fill=$node.GetAttribute('fill')
		if($fill -eq 'url(#grid)') {
			$pen=New-Object System.Drawing.Pen(([System.Drawing.Color]::FromArgb(34,221,226,238)),1)
			for($gx=64;$gx -lt $width;$gx+=64){$g.DrawLine($pen,$gx,0,$gx,$height)}
			for($gy=64;$gy -lt $height;$gy+=64){$g.DrawLine($pen,0,$gy,$width,$gy)}
			$pen.Dispose(); return
		}
		$p=Rounded-Path $x $y $w $h $r
		if($fill -and $fill -ne 'none'){$b=New-Object System.Drawing.SolidBrush((Color-FromHex $fill));$g.FillPath($b,$p);$b.Dispose()}
		$stroke=$node.GetAttribute('stroke')
		if($stroke -and $stroke -ne 'none'){$sw=1;if($node.HasAttribute('stroke-width')){$sw=[float]$node.GetAttribute('stroke-width')};$pen=New-Object System.Drawing.Pen((Color-FromHex $stroke),$sw);$g.DrawPath($pen,$p);$pen.Dispose()}
		$p.Dispose(); return
	}
	if($name -eq 'circle') {
		[float]$cx=$node.GetAttribute('cx');[float]$cy=$node.GetAttribute('cy');[float]$r=$node.GetAttribute('r');$b=New-Object System.Drawing.SolidBrush((Color-FromHex $node.GetAttribute('fill')));$g.FillEllipse($b,$cx-$r,$cy-$r,2*$r,2*$r);$b.Dispose();return
	}
	if($name -eq 'path') {
		$stroke=$node.GetAttribute('stroke');if(-not $stroke -or $stroke -eq 'none'){return};$sw=1;if($node.HasAttribute('stroke-width')){$sw=[float]$node.GetAttribute('stroke-width')};$op=1.0;if($node.HasAttribute('opacity')){$op=[double]$node.GetAttribute('opacity')};$pen=New-Object System.Drawing.Pen((Color-FromHex $stroke $op),$sw);$pen.StartCap=[System.Drawing.Drawing2D.LineCap]::Round;$pen.EndCap=[System.Drawing.Drawing2D.LineCap]::Round;$pen.LineJoin=[System.Drawing.Drawing2D.LineJoin]::Round;Draw-PathData $g $node.GetAttribute('d') $pen;$pen.Dispose();return
	}
	if($name -eq 'image') {
		$href=$node.GetAttribute('href');$base=[IO.Path]::GetDirectoryName((Resolve-Path $SvgPath).Path);$imgPath=[IO.Path]::GetFullPath((Join-Path $base $href));$img=[System.Drawing.Image]::FromFile($imgPath);[float]$x=$node.GetAttribute('x');[float]$y=$node.GetAttribute('y');[float]$w=$node.GetAttribute('width');[float]$h=$node.GetAttribute('height');$old=$g.InterpolationMode;$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor;$rect=[System.Drawing.RectangleF]::new($x,$y,$w,$h);$g.DrawImage($img,$rect);$g.InterpolationMode=$old;$img.Dispose();return
	}
	if($name -eq 'text') {
		[float]$size=$node.GetAttribute('font-size');$weight=$node.GetAttribute('font-weight');$style=if($weight -eq '700'){[System.Drawing.FontStyle]::Bold}else{[System.Drawing.FontStyle]::Regular};$font=New-Object System.Drawing.Font('Malgun Gothic',$size,$style,[System.Drawing.GraphicsUnit]::Pixel);$brush=New-Object System.Drawing.SolidBrush((Color-FromHex $node.GetAttribute('fill')));$format=[System.Drawing.StringFormat]::GenericTypographic.Clone();$format.FormatFlags=$format.FormatFlags -bor [System.Drawing.StringFormatFlags]::NoClip
		$anchor=$node.GetAttribute('text-anchor');[float]$x=$node.GetAttribute('x');[float]$y=$node.GetAttribute('y');$lineY=$y
		foreach($tspan in $node.ChildNodes){if($tspan.LocalName -ne 'tspan'){continue};if($tspan.HasAttribute('x')){$x=[float]$tspan.GetAttribute('x')};if($tspan.HasAttribute('dy')){$lineY += [float]$tspan.GetAttribute('dy')};$str=$tspan.InnerText;$measure=$g.MeasureString($str,$font,[int]10000,$format);[float]$drawX=$x;if($anchor -eq 'middle'){$drawX=[float]($drawX-$measure.Width/2)}elseif($anchor -eq 'end'){$drawX=[float]($drawX-$measure.Width)};$point=[System.Drawing.PointF]::new($drawX,[float]($lineY-$size*0.92));$g.DrawString($str,$font,$brush,$point,$format)}
		$format.Dispose();$brush.Dispose();$font.Dispose();return
	}
}

foreach($child in $root.ChildNodes){ Draw-Element $child }
$bitmap.Save($PngPath,[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$bitmap.Dispose()
