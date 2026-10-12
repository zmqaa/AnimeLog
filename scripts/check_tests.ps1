param([string]$FlutterPath = 'D:\dev\flutter\bin\flutter.bat')

$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $FlutterPath -PathType Leaf)) {
    throw '请通过 -FlutterPath 指定本机 Flutter 可执行文件。'
}
Push-Location -LiteralPath $taskRoot
try {
    # Fresh runner per file avoids intermittent Windows LiveTest process exits.
    $taskTestFiles = Get-ChildItem -LiteralPath (Join-Path $taskRoot 'test') -Recurse -File -Filter '*_test.dart' | Sort-Object FullName
    foreach ($taskTestFile in $taskTestFiles) {
        Write-Output "检查 $($taskTestFile.Name)"
        & $FlutterPath test $taskTestFile.FullName --no-pub -j 1 --reporter expanded
        if ($LASTEXITCODE -ne 0) {
            throw "测试未通过：$($taskTestFile.FullName)"
        }
    }
    Write-Output "全部 $($taskTestFiles.Count) 个测试文件通过。"
}
finally {
    Pop-Location
}
