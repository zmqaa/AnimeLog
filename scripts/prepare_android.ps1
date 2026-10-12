param(
    [string]$FlutterPath = 'D:\dev\flutter\bin\flutter.bat',
    [ValidateSet('debug', 'release')]
    [string]$BuildMode = 'release',
    [switch]$Online
)

$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $FlutterPath -PathType Leaf)) {
    throw '请通过 -FlutterPath 指定本机 Flutter 可执行文件。'
}

Push-Location -LiteralPath $taskRoot
try {
    # Flutter owns this generated file. Refresh through its supported command;
    # never hand-edit GeneratedPluginRegistrant.java or register plugins twice.
    if ($Online) {
        & $FlutterPath pub get
    }
    else {
        & $FlutterPath pub get --offline
    }
    if ($LASTEXITCODE -ne 0) {
        throw 'Flutter 插件元数据刷新失败；请先处理上述错误，不要继续打包。依赖未缓存时可显式使用 -Online。'
    }

    # Pub get prepares every plugin, including dev-only plugins. Regenerate the
    # Android files for the selected mode through Flutter before invoking Gradle.
    # --no-pub also skips mode-specific regeneration in the current SDK, so keep
    # pub enabled here after the explicit cached dependency refresh above.
    & $FlutterPath build apk "--$BuildMode" --config-only
    if ($LASTEXITCODE -ne 0) {
        throw 'Flutter Android 构建模式配置失败；停止后续打包。'
    }

    $taskRegistrant = Join-Path $taskRoot 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
    $taskSource = Get-Content -LiteralPath $taskRegistrant -Raw -Encoding utf8
    foreach ($taskPlugin in @(
        'com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin',
        'com.mr.flutter.plugin.filepicker.FilePickerPlugin'
    )) {
        $taskPattern = 'new\s+' + [regex]::Escape($taskPlugin) + '\s*\('
        if ($taskSource -notmatch $taskPattern) {
            throw "Android 插件未正确注册：$taskPlugin。停止后续打包。"
        }
    }

    if ($BuildMode -eq 'release' -and $taskSource -match 'new\s+dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin\s*\(') {
        throw 'release 插件注册表仍包含测试插件，停止后续打包。'
    }

    $taskPubspec = Get-Content -LiteralPath (Join-Path $taskRoot 'pubspec.yaml') -Raw -Encoding utf8
    $taskVersion = [regex]::Match($taskPubspec, '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$')
    if (-not $taskVersion.Success) {
        throw 'pubspec.yaml 中缺少有效的 versionName+versionCode。'
    }
    $taskPropertiesPath = Join-Path $taskRoot 'android/local.properties'
    $taskProperties = Get-Content -LiteralPath $taskPropertiesPath -Raw -Encoding utf8
    $taskNewline = if ($taskProperties.Contains("`r`n")) { "`r`n" } else { "`n" }
    $taskValues = [ordered]@{
        'flutter.versionName' = $taskVersion.Groups[1].Value
        'flutter.versionCode' = $taskVersion.Groups[2].Value
        'flutter.buildMode' = $BuildMode
    }
    foreach ($taskProperty in $taskValues.GetEnumerator()) {
        $taskPattern = '(?m)^' + [regex]::Escape($taskProperty.Key) + '=[^\r\n]*'
        $taskLine = $taskProperty.Key + '=' + $taskProperty.Value
        if ($taskProperties -match $taskPattern) {
            $taskProperties = [regex]::Replace($taskProperties, $taskPattern, $taskLine)
        }
        else {
            $taskProperties = $taskProperties.TrimEnd([char[]]"`r`n") + $taskNewline + $taskLine + $taskNewline
        }
    }
    [IO.File]::WriteAllText($taskPropertiesPath, $taskProperties, [Text.UTF8Encoding]::new($false))
    Write-Output "Android 插件注册及 $BuildMode 版本配置已就绪。本脚本不编译、不打包、不运行应用或测试。"
}
finally {
    Pop-Location
}
