param(
	[string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..'))
)

Add-Type -AssemblyName System.Drawing
$report = Join-Path $RepoRoot 'reports/codex-qa-15'
$evidence = Join-Path $report 'evidence'
$contact = Join-Path $report 'contact_sheets'
New-Item -ItemType Directory -Force $evidence | Out-Null
New-Item -ItemType Directory -Force $contact | Out-Null

function Save-ContactSheet {
	param([System.IO.FileInfo[]]$Files, [string]$Dest, [int]$Columns, [int]$ThumbWidth, [int]$ThumbHeight)
	$labelHeight = 26
	$rows = [Math]::Ceiling($Files.Count / [double]$Columns)
	$dst = New-Object System.Drawing.Bitmap ($ThumbWidth * $Columns), ([int](($ThumbHeight + $labelHeight) * $rows))
	$graphics = [System.Drawing.Graphics]::FromImage($dst)
	$font = New-Object System.Drawing.Font 'Arial', 11
	try {
		$graphics.Clear([System.Drawing.Color]::FromArgb(18, 18, 24))
		$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
		for ($index = 0; $index -lt $Files.Count; $index++) {
			$image = [System.Drawing.Image]::FromFile($Files[$index].FullName)
			try {
				$x = ($index % $Columns) * $ThumbWidth
				$y = [Math]::Floor($index / $Columns) * ($ThumbHeight + $labelHeight)
				$graphics.DrawImage($image, $x, $y, $ThumbWidth, $ThumbHeight)
				$graphics.DrawString($Files[$index].Name, $font, [System.Drawing.Brushes]::White, $x + 4, $y + $ThumbHeight + 3)
			} finally {
				$image.Dispose()
			}
		}
		$dst.Save($Dest, [System.Drawing.Imaging.ImageFormat]::Png)
	} finally {
		$font.Dispose()
		$graphics.Dispose()
		$dst.Dispose()
	}
}

function Save-Crop {
	param([string]$Source, [string]$Dest, [int]$X, [int]$Y, [int]$W, [int]$H, [double]$Scale)
	$src = [System.Drawing.Bitmap]::FromFile((Resolve-Path $Source))
	$outWidth = [int]($W * $Scale)
	$outHeight = [int]($H * $Scale)
	$dst = New-Object System.Drawing.Bitmap $outWidth, $outHeight
	$graphics = [System.Drawing.Graphics]::FromImage($dst)
	try {
		$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
		$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
		$graphics.DrawImage($src, [System.Drawing.Rectangle]::new(0, 0, $outWidth, $outHeight), [System.Drawing.Rectangle]::new($X, $Y, $W, $H), [System.Drawing.GraphicsUnit]::Pixel)
		$dst.Save($Dest, [System.Drawing.Imaging.ImageFormat]::Png)
	} finally {
		$graphics.Dispose()
		$dst.Dispose()
		$src.Dispose()
	}
}

function Save-Compare {
	param([string]$SourceA, [string]$SourceB, [string]$Dest, [int]$X, [int]$Y, [int]$W, [int]$H, [double]$Scale, [string]$LabelA, [string]$LabelB)
	$a = [System.Drawing.Bitmap]::FromFile((Resolve-Path $SourceA))
	$b = [System.Drawing.Bitmap]::FromFile((Resolve-Path $SourceB))
	$cellWidth = [int]($W * $Scale)
	$cellHeight = [int]($H * $Scale)
	$labelHeight = 32
	$dst = New-Object System.Drawing.Bitmap ($cellWidth * 2), ($cellHeight + $labelHeight)
	$graphics = [System.Drawing.Graphics]::FromImage($dst)
	$font = New-Object System.Drawing.Font 'Arial', 14, ([System.Drawing.FontStyle]::Bold)
	try {
		$graphics.Clear([System.Drawing.Color]::FromArgb(18, 18, 24))
		$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
		$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
		$sourceRect = [System.Drawing.Rectangle]::new($X, $Y, $W, $H)
		$graphics.DrawImage($a, [System.Drawing.Rectangle]::new(0, $labelHeight, $cellWidth, $cellHeight), $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
		$graphics.DrawImage($b, [System.Drawing.Rectangle]::new($cellWidth, $labelHeight, $cellWidth, $cellHeight), $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
		$graphics.DrawString($LabelA, $font, [System.Drawing.Brushes]::White, 8, 4)
		$graphics.DrawString($LabelB, $font, [System.Drawing.Brushes]::White, $cellWidth + 8, 4)
		$dst.Save($Dest, [System.Drawing.Imaging.ImageFormat]::Png)
	} finally {
		$font.Dispose()
		$graphics.Dispose()
		$dst.Dispose()
		$a.Dispose()
		$b.Dispose()
	}
}

function Save-CompareRegions {
	param([string]$SourceA, [string]$SourceB, [string]$Dest, [int]$XA, [int]$YA, [int]$XB, [int]$YB, [int]$W, [int]$H, [double]$Scale, [string]$LabelA, [string]$LabelB)
	$a = [System.Drawing.Bitmap]::FromFile((Resolve-Path $SourceA))
	$b = [System.Drawing.Bitmap]::FromFile((Resolve-Path $SourceB))
	$cellWidth = [int]($W * $Scale)
	$cellHeight = [int]($H * $Scale)
	$labelHeight = 32
	$dst = New-Object System.Drawing.Bitmap ($cellWidth * 2), ($cellHeight + $labelHeight)
	$graphics = [System.Drawing.Graphics]::FromImage($dst)
	$font = New-Object System.Drawing.Font 'Arial', 14, ([System.Drawing.FontStyle]::Bold)
	try {
		$graphics.Clear([System.Drawing.Color]::FromArgb(18, 18, 24))
		$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
		$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
		$graphics.DrawImage($a, [System.Drawing.Rectangle]::new(0, $labelHeight, $cellWidth, $cellHeight), [System.Drawing.Rectangle]::new($XA, $YA, $W, $H), [System.Drawing.GraphicsUnit]::Pixel)
		$graphics.DrawImage($b, [System.Drawing.Rectangle]::new($cellWidth, $labelHeight, $cellWidth, $cellHeight), [System.Drawing.Rectangle]::new($XB, $YB, $W, $H), [System.Drawing.GraphicsUnit]::Pixel)
		$graphics.DrawString($LabelA, $font, [System.Drawing.Brushes]::White, 8, 4)
		$graphics.DrawString($LabelB, $font, [System.Drawing.Brushes]::White, $cellWidth + 8, 4)
		$dst.Save($Dest, [System.Drawing.Imaging.ImageFormat]::Png)
	} finally {
		$font.Dispose()
		$graphics.Dispose()
		$dst.Dispose()
		$a.Dispose()
		$b.Dispose()
	}
}

$screens = Join-Path $report 'screens'
$coreFiles = @(Get-ChildItem -LiteralPath (Join-Path $screens 'core') -File -Filter '*.png' | Sort-Object Name)
$attackFiles = @(Get-ChildItem -LiteralPath (Join-Path $screens 'attacks') -File -Filter '*.png' | Sort-Object Name)
$ultimateFiles = @(Get-ChildItem -LiteralPath (Join-Path $screens 'ultimates') -File -Filter '*.png' | Sort-Object Name)
$supplementalFiles = @(Get-ChildItem -LiteralPath (Join-Path $screens 'supplemental') -File -Filter '*.png' | Sort-Object Name)
Save-ContactSheet $coreFiles (Join-Path $contact 'core.png') 3 320 180
Save-ContactSheet $attackFiles (Join-Path $contact 'attacks.png') 3 320 180
Save-ContactSheet $ultimateFiles (Join-Path $contact 'ultimates.png') 2 320 180
Save-ContactSheet @($supplementalFiles | Where-Object Name -Match '^realm_0[1-3]_') (Join-Path $contact 'realms_01_03.png') 3 426 240
Save-ContactSheet @($supplementalFiles | Where-Object Name -Match '^realm_0[4-6]_') (Join-Path $contact 'realms_04_06.png') 3 426 240
Save-ContactSheet @($supplementalFiles | Where-Object Name -Match '^realm_0[7-9]_') (Join-Path $contact 'realms_07_09.png') 3 426 240
Save-ContactSheet @($supplementalFiles | Where-Object Name -Match '^(00_|object_|hazard_)') (Join-Path $contact 'objects_hazards.png') 3 426 240

Save-Crop (Join-Path $screens 'supplemental/00_hud_bot_panel.png') (Join-Path $evidence '01_bot_panel_2x.png') 900 80 380 420 2
Save-Crop (Join-Path $screens 'supplemental/hazard_07_warning.png') (Join-Path $evidence '02_top_hud_overlap_2x.png') 360 0 840 86 2
Save-Crop (Join-Path $screens 'ultimates/yuki_0.png') (Join-Path $evidence '03_yuki_seal_placeholder_3x.png') 585 360 245 180 3
Save-Crop (Join-Path $screens 'supplemental/hazard_08_warning.png') (Join-Path $evidence '04_quake_bars_2x.png') 210 80 900 260 2
Save-Crop (Join-Path $screens 'core/07_results.png') (Join-Path $evidence '05_results_hud_2x.png') 850 0 430 470 2
Save-Compare (Join-Path $screens 'supplemental/hazard_07_warning.png') (Join-Path $screens 'supplemental/hazard_07_active.png') (Join-Path $evidence '06_vine_warning_active.png') 330 400 610 250 1.5 'warning' 'active'
Save-Compare (Join-Path $screens 'supplemental/hazard_01_active.png') (Join-Path $screens 'supplemental/hazard_05_active.png') (Join-Path $evidence '07_stretched_hazards.png') 400 120 300 540 1 'beam (105 x 1080 world)' 'fire (120 x 690 world)'
Save-Crop (Join-Path $screens 'supplemental/hazard_08_active.png') (Join-Path $evidence '08_control_hint_overlap.png') 0 540 920 180 1.5
Save-CompareRegions (Join-Path $screens 'supplemental/hazard_07_active.png') (Join-Path $screens 'supplemental/hazard_05_active.png') (Join-Path $evidence '09_monster_camouflage.png') 390 285 470 150 330 210 1.5 'Mossling / Vanaheim' 'Ember Imp / Muspelheim'
Save-Crop (Join-Path $screens 'core/07_results.png') (Join-Path $evidence '10_results_card_ids_2x.png') 720 230 310 330 2
Save-Crop (Join-Path $screens 'supplemental/hazard_07_warning.png') (Join-Path $evidence '11_minimap_3x.png') 10 40 220 140 3

Get-ChildItem -LiteralPath $evidence -File | Select-Object Name, Length
