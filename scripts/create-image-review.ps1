param([int]$PageSize = 35)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$rootDirectory = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$catalog = Get-Content -LiteralPath (Join-Path $rootDirectory 'content/products.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$products = @($catalog.products | Where-Object { $_.image })
$tileWidth = 180
$tileHeight = 215
$columns = 7
$font = New-Object System.Drawing.Font('Segoe UI', 9)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(23, 59, 40))
$textFormat = New-Object System.Drawing.StringFormat
$textFormat.Trimming = [System.Drawing.StringTrimming]::EllipsisCharacter
for ($offset = 0; $offset -lt $products.Count; $offset += $PageSize) {
    $count = [Math]::Min($PageSize, $products.Count - $offset)
    $rows = [int][Math]::Ceiling($count / [double]$columns)
    $canvas = New-Object System.Drawing.Bitmap(($columns * $tileWidth), ($rows * $tileHeight))
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.Clear([System.Drawing.Color]::White)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    for ($index = 0; $index -lt $count; $index++) {
        $product = $products[$offset + $index]
        $x = ($index % $columns) * $tileWidth
        $y = [int][Math]::Floor($index / $columns) * $tileHeight
        $sourcePath = Join-Path $rootDirectory ($product.image.TrimStart('/'))
        $source = [System.Drawing.Image]::FromFile($sourcePath)
        try { $graphics.DrawImage($source, $x + 5, $y + 5, 170, 170) }
        finally { $source.Dispose() }
        $rectangle = New-Object System.Drawing.RectangleF(($x + 5), ($y + 177), 170, 36)
        $graphics.DrawString($product.name_en, $font, $brush, $rectangle, $textFormat)
    }
    $page = [int]($offset / $PageSize) + 1
    $reviewPath = Join-Path $rootDirectory "docs/image-review-$page.jpg"
    try { $canvas.Save($reviewPath, [System.Drawing.Imaging.ImageFormat]::Jpeg) }
    finally { $graphics.Dispose(); $canvas.Dispose() }
}
$textFormat.Dispose()
$brush.Dispose()
$font.Dispose()
Write-Output "Created image review sheets for $($products.Count) products."
