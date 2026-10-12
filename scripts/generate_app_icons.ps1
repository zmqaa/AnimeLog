param([string]$SourcePath)

$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $SourcePath = Join-Path $taskRoot 'assets/branding/app_icon.png'
}
Add-Type -AssemblyName System.Drawing

function New-AppIconBitmap {
    param(
        [System.Drawing.Image]$Source,
        [int]$Size,
        [int]$ArtworkSize = $Size
    )
    $taskBitmap = [Drawing.Bitmap]::new($Size, $Size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $taskGraphics = [Drawing.Graphics]::FromImage($taskBitmap)
    try {
        $taskGraphics.Clear([Drawing.Color]::Transparent)
        $taskGraphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $taskGraphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $taskInset = [int](($Size - $ArtworkSize) / 2)
        $taskRectangle = [Drawing.Rectangle]::new($taskInset, $taskInset, $ArtworkSize, $ArtworkSize)
        $taskGraphics.DrawImage($Source, $taskRectangle)
    }
    catch {
        $taskBitmap.Dispose()
        throw
    }
    finally {
        $taskGraphics.Dispose()
    }
    return $taskBitmap
}

$taskSource = [Drawing.Bitmap]::new((Resolve-Path -LiteralPath $SourcePath).Path)
try {
    if ($taskSource.Width -ne $taskSource.Height) {
        throw '应用图标源文件必须是正方形。'
    }
    # Only resize and pad the imported artwork; preserve its composition.
    $taskDensities = [ordered]@{
        'mdpi' = 1.0
        'hdpi' = 1.5
        'xhdpi' = 2.0
        'xxhdpi' = 3.0
        'xxxhdpi' = 4.0
    }
    foreach ($taskDensity in $taskDensities.GetEnumerator()) {
        $taskDirectory = Join-Path $taskRoot ('android/app/src/main/res/mipmap-' + $taskDensity.Key)
        New-Item -ItemType Directory -Path $taskDirectory -Force | Out-Null
        $taskLegacy = New-AppIconBitmap -Source $taskSource -Size ([int](48 * $taskDensity.Value))
        try {
            $taskLegacy.Save((Join-Path $taskDirectory 'ic_launcher.png'), [Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $taskLegacy.Dispose()
        }
        # Adaptive layers are 108 dp. Keep all artwork inside the 66 dp safe zone.
        $taskForeground = New-AppIconBitmap -Source $taskSource -Size ([int](108 * $taskDensity.Value)) -ArtworkSize ([int](66 * $taskDensity.Value))
        try {
            $taskForeground.Save((Join-Path $taskDirectory 'ic_launcher_foreground.png'), [Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $taskForeground.Dispose()
        }
    }

    $taskSizes = @(16, 24, 32, 48, 64, 128, 256)
    $taskLayers = [Collections.Generic.List[byte[]]]::new()
    foreach ($taskSize in $taskSizes) {
        $taskBitmap = New-AppIconBitmap -Source $taskSource -Size $taskSize
        $taskMemory = [IO.MemoryStream]::new()
        try {
            $taskBitmap.Save($taskMemory, [Drawing.Imaging.ImageFormat]::Png)
            $taskLayers.Add($taskMemory.ToArray())
        }
        finally {
            $taskMemory.Dispose()
            $taskBitmap.Dispose()
        }
    }
    $taskIcoPath = Join-Path $taskRoot 'windows/runner/resources/app_icon.ico'
    $taskStream = [IO.File]::Open($taskIcoPath, [IO.FileMode]::Create)
    $taskWriter = [IO.BinaryWriter]::new($taskStream)
    try {
        $taskWriter.Write([uint16]0)
        $taskWriter.Write([uint16]1)
        $taskWriter.Write([uint16]$taskSizes.Count)
        $taskOffset = 6 + 16 * $taskSizes.Count
        for ($taskIndex = 0; $taskIndex -lt $taskSizes.Count; $taskIndex++) {
            $taskDimension = if ($taskSizes[$taskIndex] -eq 256) { 0 } else { $taskSizes[$taskIndex] }
            $taskWriter.Write([byte]$taskDimension)
            $taskWriter.Write([byte]$taskDimension)
            $taskWriter.Write([byte]0)
            $taskWriter.Write([byte]0)
            $taskWriter.Write([uint16]1)
            $taskWriter.Write([uint16]32)
            $taskWriter.Write([uint32]$taskLayers[$taskIndex].Length)
            $taskWriter.Write([uint32]$taskOffset)
            $taskOffset += $taskLayers[$taskIndex].Length
        }
        foreach ($taskLayer in $taskLayers) {
            $taskWriter.Write($taskLayer)
        }
    }
    finally {
        $taskWriter.Dispose()
        $taskStream.Dispose()
    }
}
finally {
    $taskSource.Dispose()
}
Write-Output '已生成五种 Android 图标／自适应前景及七种尺寸的 Windows ICO。'
