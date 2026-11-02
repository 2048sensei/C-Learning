#!/usr/bin/env pwsh
<#
.SYNOPSIS
    校验便携发布包：清单完整性、文件 SHA-256、顶层结构。

.DESCRIPTION
    读取 学习资源/release-info.json，逐条核对清单里的路径是否存在、哈希是否一致，
    并反向检查 学习资源/ 下是否有清单遗漏的文件。
    任何一项不通过都会以退出码 1 结束，可直接用于 CI。

.PARAMETER Root
    仓库根目录，默认为脚本所在目录的上一级。

.EXAMPLE
    pwsh ./scripts/verify-release.ps1
#>
[CmdletBinding()]
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$manifestPath = Join-Path $Root '学习资源/release-info.json'
$siteRoot = Join-Path $Root '学习资源'
$launcher = Join-Path $Root '开始学习.exe'
$manifestName = 'release-info.json'

$failures = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $siteRoot -PathType Container)) {
    throw "找不到站点目录：$siteRoot"
}
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "找不到发布清单：$manifestPath"
}
if (-not (Test-Path -LiteralPath (Join-Path $siteRoot 'index.html') -PathType Leaf)) {
    $failures.Add('站点缺少入口文件：学习资源/index.html')
}
if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {
    $failures.Add('缺少便携启动器：开始学习.exe')
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$entries = @($manifest.files)

Write-Host ("发布清单：version {0} · builtAt {1} · {2} 个文件" -f $manifest.version, $manifest.builtAt, $entries.Count)

$listed = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)

foreach ($entry in $entries) {
    $relative = ([string]$entry.path).Replace('\', '/')
    $expected = ([string]$entry.sha256).ToUpperInvariant()
    [void]$listed.Add($relative)

    if ($relative -ne '开始学习.exe' -and -not $relative.StartsWith('学习资源/')) {
        $failures.Add("清单路径越界：$relative")
        continue
    }
    if ($relative.Contains('..')) {
        $failures.Add("清单路径包含上级目录：$relative")
        continue
    }

    $full = Join-Path $Root $relative
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        $failures.Add("清单文件缺失：$relative")
        continue
    }

    $actual = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actual -ne $expected) {
        $failures.Add("哈希不一致：$relative`n    期望 $expected`n    实际 $actual")
    }
}

# 反向检查：站点目录里的文件都应出现在清单中（清单自身除外）
$siteFiles = Get-ChildItem -LiteralPath $siteRoot -Recurse -File -Force
foreach ($file in $siteFiles) {
    $relative = '学习资源/' + ([System.IO.Path]::GetRelativePath($siteRoot, $file.FullName)).Replace('\', '/')
    if ($relative -eq "学习资源/$manifestName") { continue }
    if (-not $listed.Contains($relative)) {
        $failures.Add("清单遗漏文件：$relative（新增或修改后请运行 update-release-info.ps1）")
    }
}

Write-Host ("已核对 {0} 个清单条目，站点共 {1} 个文件。" -f $entries.Count, $siteFiles.Count)

if ($failures.Count -gt 0) {
    Write-Host ''
    foreach ($failure in $failures) {
        Write-Host "  ✗ $failure" -ForegroundColor Red
    }
    Write-Host ''
    Write-Host ("校验失败：{0} 项问题。" -f $failures.Count) -ForegroundColor Red
    exit 1
}

Write-Host '校验通过：路径与哈希全部一致。' -ForegroundColor Green
exit 0
