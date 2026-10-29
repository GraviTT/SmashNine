$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$inputs = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'contact-sheet-inputs.json') -Encoding UTF8 -Raw | ConvertFrom-Json
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$font = New-Object System.Drawing.Font('Malgun Gothic', 26, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$small = New-Object System.Drawing.Font('Malgun Gothic', 22, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(240,233,255))
$bandBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200,8,12,25))
try {
    foreach ($item in $inputs) {
        if (Test-Path -LiteralPath $item.path) { throw "Refusing to overwrite $($item.path)" }
        $canvas = New-Object System.Drawing.Bitmap(3840,828,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $graphics = [System.Drawing.Graphics]::FromImage($canvas)
        try {
            $graphics.Clear([System.Drawing.Color]::FromArgb(17,21,34))
            $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
            for ($i=0; $i -lt 3; $i++) {
                $tile = [System.Drawing.Image]::FromFile($item.tiles[$i])
                try {
                    if ($tile.Width -ne 1280 -or $tile.Height -ne 720) { throw 'Tile dimensions must be 1280x720.' }
                    $graphics.DrawImageUnscaled($tile,1280*$i,60)
                    $graphics.FillRectangle($bandBrush,1280*$i,600,1280,180)
                } finally { $tile.Dispose() }
                $title = if ($i -eq 2) { 'ART-70 cg_prologue / style anchor' } else { $item.names[$i] }
                $graphics.DrawString($title,$font,$textBrush,[single](1280*$i+22),[single]16)
            }
            $graphics.DrawString('1280x720 each / bottom 25% dialogue overlay for review only / PNG candidates have no band',$small,$textBrush,[single]22,[single]790)
            $parameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
            try {
                $parameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality,[long]90)
                $canvas.Save($item.path,$codec,$parameters)
            } finally { $parameters.Dispose() }
            if ((Get-Item -LiteralPath $item.path).Length -gt 2000000) { throw 'JPEG exceeds 2 MB.' }
            Write-Output $item.path
        } finally { $graphics.Dispose(); $canvas.Dispose() }
    }
} finally { $font.Dispose(); $small.Dispose(); $textBrush.Dispose(); $bandBrush.Dispose() }
