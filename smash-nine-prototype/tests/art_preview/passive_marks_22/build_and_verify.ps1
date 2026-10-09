$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
$repoRoot = (Resolve-Path (Join-Path $projectRoot "..")).Path
$outputDir = Join-Path $projectRoot "assets/art/effects/passive"
$reportDir = Join-Path $repoRoot "reports/codex-art-22"
$contactDir = Join-Path $reportDir "contact"
New-Item -ItemType Directory -Force $outputDir, $contactDir | Out-Null

$specs = @(
    [pscustomobject]@{ Name = "frey_pursuit_mark"; Source = "frey_pursuit_mark_imagegen.png"; Width = 64; Height = 40; FitWidth = 60; FitHeight = 36; Palette = @("#151B35", "#8A541E", "#FFB85C", "#FFD27A", "#FFF2C4", "#FFFFFF") },
    [pscustomobject]@{ Name = "frey_spike_ring"; Source = "frey_spike_ring_imagegen.png"; Width = 96; Height = 96; FitWidth = 92; FitHeight = 92; Palette = @("#151B35", "#8A541E", "#FFB85C", "#FFD27A", "#FFF2C4", "#FFFFFF") },
    [pscustomobject]@{ Name = "luna_star_charge"; Source = "luna_star_charge_imagegen.png"; Width = 18; Height = 18; FitWidth = 14; FitHeight = 14; Palette = @("#662A91", "#FFE06B", "#FFFFFF") }
)

function Get-OpaqueBounds([System.Drawing.Bitmap]$bitmap, [int]$cutoff = 46) {
    $rectangle = [System.Drawing.Rectangle]::new(0, 0, $bitmap.Width, $bitmap.Height)
    $data = $bitmap.LockBits($rectangle, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $stride = [Math]::Abs($data.Stride)
        $bytes = [byte[]]::new($stride * $bitmap.Height)
        [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
        $minX = $bitmap.Width; $minY = $bitmap.Height; $maxX = -1; $maxY = -1
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                if ($bytes[$y * $stride + $x * 4 + 3] -ge $cutoff) {
                    if ($x -lt $minX) { $minX = $x }
                    if ($y -lt $minY) { $minY = $y }
                    if ($x -gt $maxX) { $maxX = $x }
                    if ($y -gt $maxY) { $maxY = $y }
                }
            }
        }
    }
    finally { $bitmap.UnlockBits($data) }
    if ($maxX -lt $minX) { return [System.Drawing.Rectangle]::Empty }
    return [System.Drawing.Rectangle]::new($minX, $minY, $maxX - $minX + 1, $maxY - $minY + 1)
}

function Get-NearestPaletteColor([System.Drawing.Color]$source, [System.Drawing.Color[]]$palette) {
    $best = $palette[0]
    $bestDistance = [double]::PositiveInfinity
    foreach ($candidate in $palette) {
        $dr = [double]$source.R - $candidate.R
        $dg = [double]$source.G - $candidate.G
        $db = [double]$source.B - $candidate.B
        $distance = $dr * $dr + $dg * $dg + $db * $db
        if ($distance -lt $bestDistance) { $bestDistance = $distance; $best = $candidate }
    }
    return $best
}

function Convert-Source([string]$sourcePath, $spec) {
    $source = [System.Drawing.Bitmap]::new($sourcePath)
    try {
        $bounds = Get-OpaqueBounds $source
        if ($bounds.IsEmpty) { throw "No opaque pixels in $sourcePath" }
        $scale = [Math]::Min($spec.FitWidth / [double]$bounds.Width, $spec.FitHeight / [double]$bounds.Height)
        $targetWidth = [Math]::Max(1, [int][Math]::Round($bounds.Width * $scale))
        $targetHeight = [Math]::Max(1, [int][Math]::Round($bounds.Height * $scale))
        $offsetX = [int](($spec.Width - $targetWidth) / 2)
        $offsetY = [int](($spec.Height - $targetHeight) / 2)
        $palette = [System.Drawing.Color[]]@($spec.Palette | ForEach-Object { [System.Drawing.ColorTranslator]::FromHtml($_) })
        $result = [System.Drawing.Bitmap]::new($spec.Width, $spec.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        for ($dy = 0; $dy -lt $targetHeight; $dy++) {
            $sy = $bounds.Y + [Math]::Min($bounds.Height - 1, [int][Math]::Floor(($dy + 0.5) * $bounds.Height / $targetHeight))
            for ($dx = 0; $dx -lt $targetWidth; $dx++) {
                $sx = $bounds.X + [Math]::Min($bounds.Width - 1, [int][Math]::Floor(($dx + 0.5) * $bounds.Width / $targetWidth))
                $pixel = $source.GetPixel($sx, $sy)
                if ($pixel.A -ge 46) {
                    $mapped = Get-NearestPaletteColor $pixel $palette
                    $result.SetPixel($offsetX + $dx, $offsetY + $dy, [System.Drawing.Color]::FromArgb(255, $mapped.R, $mapped.G, $mapped.B))
                }
            }
        }
        return $result
    }
    finally { $source.Dispose() }
}

function New-FighterCell([string]$path) {
    $sheet = [System.Drawing.Bitmap]::new($path)
    try {
        $cell = [System.Drawing.Bitmap]::new(128, 128, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($cell)
        try { $graphics.DrawImage($sheet, [System.Drawing.Rectangle]::new(0, 0, 128, 128), 0, 0, 128, 128, [System.Drawing.GraphicsUnit]::Pixel) }
        finally { $graphics.Dispose() }
        return $cell
    }
    finally { $sheet.Dispose() }
}

function Set-Nearest([System.Drawing.Graphics]$graphics) {
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
}

function Get-ConnectedComponents([System.Drawing.Bitmap]$bitmap) {
    $opaque = New-Object 'bool[,]' $bitmap.Width, $bitmap.Height
    $visited = New-Object 'bool[,]' $bitmap.Width, $bitmap.Height
    for ($y = 0; $y -lt $bitmap.Height; $y++) { for ($x = 0; $x -lt $bitmap.Width; $x++) { $opaque[$x,$y] = $bitmap.GetPixel($x,$y).A -gt 127 } }
    $components = 0
    $offsets = @([Drawing.Point]::new(-1,0), [Drawing.Point]::new(1,0), [Drawing.Point]::new(0,-1), [Drawing.Point]::new(0,1))
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            if (-not $opaque[$x,$y] -or $visited[$x,$y]) { continue }
            $components++
            $queue = [System.Collections.Generic.Queue[System.Drawing.Point]]::new()
            $queue.Enqueue([Drawing.Point]::new($x,$y)); $visited[$x,$y] = $true
            while ($queue.Count -gt 0) {
                $point = $queue.Dequeue()
                foreach ($offset in $offsets) {
                    $nx = $point.X + $offset.X; $ny = $point.Y + $offset.Y
                    if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $bitmap.Width -and $ny -lt $bitmap.Height -and $opaque[$nx,$ny] -and -not $visited[$nx,$ny]) {
                        $visited[$nx,$ny] = $true; $queue.Enqueue([Drawing.Point]::new($nx,$ny))
                    }
                }
            }
        }
    }
    return $components
}

function Measure-Asset([string]$name, [System.Drawing.Bitmap]$bitmap) {
    $alpha = [System.Collections.Generic.HashSet[int]]::new()
    $colors = [System.Collections.Generic.HashSet[string]]::new()
    $visible = 0; $border = 0; $isolated = 0
    $minX = $bitmap.Width; $minY = $bitmap.Height; $maxX = -1; $maxY = -1
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x,$y); [void]$alpha.Add($pixel.A)
            if ($pixel.A -le 127) { continue }
            $visible++; [void]$colors.Add(('{0:X2}{1:X2}{2:X2}' -f $pixel.R,$pixel.G,$pixel.B))
            $minX = [Math]::Min($minX,$x); $minY = [Math]::Min($minY,$y); $maxX = [Math]::Max($maxX,$x); $maxY = [Math]::Max($maxY,$y)
            if ($x -eq 0 -or $y -eq 0 -or $x -eq $bitmap.Width-1 -or $y -eq $bitmap.Height-1) { $border++ }
            $neighbours = 0
            foreach ($offset in @(@(-1,0),@(1,0),@(0,-1),@(0,1))) {
                $nx=$x+$offset[0]; $ny=$y+$offset[1]
                if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $bitmap.Width -and $ny -lt $bitmap.Height -and $bitmap.GetPixel($nx,$ny).A -gt 127) { $neighbours++ }
            }
            if ($neighbours -eq 0) { $isolated++ }
        }
    }
    $margins = @($minX, $minY, ($bitmap.Width - 1 - $maxX), ($bitmap.Height - 1 - $maxY))
    return [pscustomobject]@{
        File = "$name.png"; Width = $bitmap.Width; Height = $bitmap.Height; Format = "RGBA8"; VisiblePixels = $visible
        AlphaValues = (($alpha | Sort-Object) -join "/"); PaletteColors = $colors.Count; PaletteValues = (($colors | Sort-Object) -join "/"); BorderPixels = $border
        BBox = "$minX`:$minY`:$($maxX-$minX+1)`:$($maxY-$minY+1)"; MinMargin = ($margins | Measure-Object -Minimum).Minimum
        Components = (Get-ConnectedComponents $bitmap); IsolatedPixels = $isolated
    }
}

$assets = @{}
foreach ($spec in $specs) {
    $sourcePath = Join-Path (Join-Path $reportDir "source") $spec.Source
    $bitmap = Convert-Source $sourcePath $spec
    $outputPath = Join-Path $outputDir ($spec.Name + ".png")
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $assets[$spec.Name] = $bitmap
}

$panelWidth = 384; $panelHeight = 192
$contact = [System.Drawing.Bitmap]::new($panelWidth * 3, $panelHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($contact)
Set-Nearest $graphics
$freyCell = New-FighterCell (Join-Path $projectRoot "assets/art/frey/frey_sheet.png")
$lunaCell = New-FighterCell (Join-Path $projectRoot "assets/art/luna/luna_sheet.png")
$backgrounds = @("realm_asgard", "realm_muspelheim", "realm_niflheim")
try {
    for ($panel = 0; $panel -lt 3; $panel++) {
        $originX = $panel * $panelWidth
        $far = [System.Drawing.Bitmap]::new((Join-Path $projectRoot ("assets/art/" + $backgrounds[$panel] + "/bg_far.png")))
        $mid = [System.Drawing.Bitmap]::new((Join-Path $projectRoot ("assets/art/" + $backgrounds[$panel] + "/bg_mid.png")))
        try {
            $graphics.DrawImage($far, [Drawing.Rectangle]::new($originX,0,$panelWidth,$panelHeight))
            $graphics.DrawImage($mid, [Drawing.Rectangle]::new($originX,0,$panelWidth,$panelHeight))
        } finally { $far.Dispose(); $mid.Dispose() }
        $freyX=$originX+32; $freyY=52
        $graphics.DrawImageUnscaled($assets.frey_spike_ring,$freyX+16,$freyY+16)
        $graphics.DrawImageUnscaled($freyCell,$freyX,$freyY)
        $graphics.DrawImageUnscaled($assets.frey_pursuit_mark,$freyX+32,$freyY-42)
        $lunaX=$originX+224; $lunaY=52
        $graphics.DrawImageUnscaled($lunaCell,$lunaX,$lunaY)
        $centerX=$lunaX+64; $centerY=$lunaY+62
        for ($star=0; $star -lt 5; $star++) {
            $angle = -[Math]::PI/2 + 2*[Math]::PI*$star/5
            $x=[int][Math]::Round($centerX+[Math]::Cos($angle)*44)-9; $y=[int][Math]::Round($centerY+[Math]::Sin($angle)*44)-9
            $graphics.DrawImageUnscaled($assets.luna_star_charge,$x,$y)
        }
    }
} finally { $graphics.Dispose(); $freyCell.Dispose(); $lunaCell.Dispose() }
$contact.Save((Join-Path $contactDir "passive_marks_contact_1x.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$four = [System.Drawing.Bitmap]::new($contact.Width*4,$contact.Height*4,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$fourGraphics=[System.Drawing.Graphics]::FromImage($four); Set-Nearest $fourGraphics
try { $fourGraphics.DrawImage($contact,[Drawing.Rectangle]::new(0,0,$four.Width,$four.Height)) } finally { $fourGraphics.Dispose() }
$four.Save((Join-Path $contactDir "passive_marks_contact_4x.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$contact.Dispose(); $four.Dispose()

$measurements = foreach ($spec in $specs) { Measure-Asset $spec.Name $assets[$spec.Name] }
$measurements | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $reportDir "measurements.csv")
$failures = @()
foreach ($measurement in $measurements) {
    if ($measurement.AlphaValues -ne "0/255") { $failures += "$($measurement.File):alpha" }
    if ($measurement.BorderPixels -ne 0 -or $measurement.MinMargin -lt 1) { $failures += "$($measurement.File):border" }
    if ($measurement.Components -ne 1 -or $measurement.IsolatedPixels -ne 0) { $failures += "$($measurement.File):stray" }
}
$failureText = $(if ($failures.Count -eq 0) { "none" } else { $failures -join "," })
@(
    "objective_verification", "assets=3", "format=RGBA8", "alpha_required=0/255", "border_pixels_required=0",
    "connected_components_required=1", "isolated_pixels_required=0", "failures=$failureText"
) | Set-Content -Encoding UTF8 (Join-Path $reportDir "verification.txt")
foreach ($asset in $assets.Values) { $asset.Dispose() }
if ($failures.Count -gt 0) { throw "Verification failed: $($failures -join ', ')" }
Write-Output "[passive_marks_22] wrote 3 assets, 2 contact sheets; all objective checks passed"
