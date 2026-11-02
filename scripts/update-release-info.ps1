#!/usr/bin/env pwsh
<#
.SYNOPSIS
    重新生成 学习资源/release-info.json 的版本、构建时间与文件哈希。

.DESCRIPTION
    收集 开始学习.exe 与 学习资源/ 下的全部文件（release-info.json 自身除外），
    按路径排序后写入清单。修改站点内容后运行一次，再执行 verify-release.ps1 复核。

.PARAMETER Version
    新的版本号，例如 1.1.1。

.PARAMETER Root
    仓库根目录，默认为脚本所在目录的上一级。

.EXAMPLE
    pwsh ./scripts/update-release-info.ps1 -Version 1.1.1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$siteRoot = Join-Path $Root '学习资源'
$manifestPath = Join-Path $siteRoot 'release-info.json'
$launcher = Join-Path $Root '开始学习.exe'

if (-not (Test-Path -LiteralPath $siteRoot -PathType Container)) {
    throw "找不到站点目录：$siteRoot"
}
if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {
    throw "找不到便携启动器：$launcher"
}

$paths = New-Object System.Collections.Generic.List[string]
$paths.Add('开始学习.exe')

Get-ChildItem -LiteralPath $siteRoot -Recurse -File -Force |
    Where-Object { $_.Name -ne 'release-info.json' } |
    ForEach-Object {
        $relative = '学习资源/' + ([System.IO.Path]::GetRelativePath($siteRoot, $_.FullName)).Replace('\', '/')
        $paths.Add($relative)
    }

$ordered = $paths | Sort-Object -Property { $_ } -CaseSensitive
$files = New-Object System.Collections.Generic.List[object]
foreach ($relative in $ordered) {
    $full = Join-Path $Root $relative
    $files.Add([ordered]@{
        path   = $relative
        sha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    })
}

$manifest = [ordered]@{
    version = $Version
    builtAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffffffzzz')
    files   = $files
}

$json = $manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($manifestPath, $json + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ("已写入 {0}：version {1} · {2} 个文件" -f $manifestPath, $Version, $files.Count) -ForegroundColor Green
