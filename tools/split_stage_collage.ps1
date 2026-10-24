# Memotong kolase referensi 12 map (Project Retro Zero) menjadi aset individual.
#   - assets/maps/<id>.png            : background arena (diperbesar 3x, bicubic)
#   - assets/map_thumbnails/<id>.png  : thumbnail ukuran asli hasil crop
# Cara pakai (dari root proyek):
#   powershell -ExecutionPolicy Bypass -File .\tools\split_stage_collage.ps1
# Catatan: label teks pada kolase dibuang; hanya area gambar arena yang dipotong.
# Untuk mengganti aset dengan gambar beresolusi tinggi, cukup timpa file PNG dengan nama yang sama.

param(
    [string]$Collage = "assets/maps/_source/stage_collage.jpg",
    [int]$Upscale = 3
)

Add-Type -AssemblyName System.Drawing

$root = (Resolve-Path "$PSScriptRoot\..").Path
$srcPath = Join-Path $root $Collage
if (-not (Test-Path $srcPath)) { throw "Kolase tidak ditemukan: $srcPath" }

$mapsDir = Join-Path $root "assets/maps"
$thumbDir = Join-Path $root "assets/map_thumbnails"
New-Item -ItemType Directory -Force -Path $mapsDir, $thumbDir | Out-Null

# Koordinat area gambar tiap map pada kolase 1024x682 (x, y, lebar, tinggi), sudah di-inset dari bingkai.
$cols = @(@(6, 328), @(348, 328), @(689, 329))
$rows = @(@(31, 143), @(199, 143), @(367, 136), @(531, 123))
$ids = @(
    "sakura_temple", "neon_city", "ruin_factory",
    "forest_shrine", "rooftop", "snow_field",
    "canyon", "moon_castle", "ancient_ruins",
    "space_station", "traditional_town", "hell_gate"
)

$src = [System.Drawing.Bitmap]::FromFile($srcPath)
try {
    for ($i = 0; $i -lt $ids.Count; $i++) {
        $c = $cols[$i % 3]
        $r = $rows[[math]::Floor($i / 3)]
        $rect = New-Object System.Drawing.Rectangle($c[0], $r[0], $c[1], $r[1])

        # Thumbnail: crop asli
        $thumb = $src.Clone($rect, $src.PixelFormat)
        $thumb.Save((Join-Path $thumbDir "$($ids[$i]).png"), [System.Drawing.Imaging.ImageFormat]::Png)

        # Background: crop diperbesar agar tidak terlalu pecah saat ditampilkan penuh
        $w = $rect.Width * $Upscale
        $h = $rect.Height * $Upscale
        $big = New-Object System.Drawing.Bitmap($w, $h)
        $g = [System.Drawing.Graphics]::FromImage($big)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.DrawImage($thumb, 0, 0, $w, $h)
        $g.Dispose()
        $big.Save((Join-Path $mapsDir "$($ids[$i]).png"), [System.Drawing.Imaging.ImageFormat]::Png)
        $big.Dispose()
        $thumb.Dispose()
        Write-Host ("[{0,2}] {1,-18} {2}x{3} -> {4}x{5}" -f ($i + 1), $ids[$i], $rect.Width, $rect.Height, $w, $h)
    }
}
finally {
    $src.Dispose()
}
Write-Host "Selesai: 12 background + 12 thumbnail dibuat."
