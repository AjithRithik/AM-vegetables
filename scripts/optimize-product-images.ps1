param([string]$SourceDirectory = (Join-Path $PSScriptRoot '../images/uploads/products'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$imageDirectory = (Resolve-Path -LiteralPath $SourceDirectory).Path
$encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
foreach ($imageFile in Get-ChildItem -LiteralPath $imageDirectory -Filter '*.png') {
    $original = [System.Drawing.Image]::FromFile($imageFile.FullName)
    $scale = [Math]::Min(1.0, 768.0 / [Math]::Max($original.Width, $original.Height))
    $width = [int][Math]::Round($original.Width * $scale)
    $height = [int][Math]::Round($original.Height * $scale)
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::White)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($original, 0, 0, $width, $height)
    $parameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $parameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]90)
    $destination = Join-Path $imageDirectory ($imageFile.BaseName + '.jpg')
    try { $bitmap.Save($destination, $encoder, $parameters) }
    finally { $parameters.Dispose(); $graphics.Dispose(); $bitmap.Dispose(); $original.Dispose() }
}
Write-Output 'Optimized product images to JPEG, maximum 768 pixels, quality 90.'
