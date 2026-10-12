$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$metadataPath = Join-Path $taskRoot '.flutter-plugins-dependencies'
if (-not (Test-Path -LiteralPath $metadataPath)) {
    throw '请先运行 flutter pub get 生成插件清单。'
}
$metadata = Get-Content -LiteralPath $metadataPath -Encoding utf8 | ConvertFrom-Json
$linkRoot = Join-Path $taskRoot 'windows\flutter\ephemeral\.plugin_symlinks'
New-Item -ItemType Directory -Path $linkRoot -Force | Out-Null
foreach ($plugin in $metadata.plugins.windows) {
    $link = Join-Path $linkRoot $plugin.name
    if (-not (Test-Path -LiteralPath $link)) {
        New-Item -ItemType Junction -Path $link -Target $plugin.path | Out-Null
    }
}
Write-Output 'Windows 插件目录连接已就绪，可使用 Flutter 的 --no-pub 构建。'
