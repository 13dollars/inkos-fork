# InkOS 本地工作台 — 开发者构建脚本
# 用途：在开发者机器上构建"小红书分发版"压缩包。
# 来源：本 fork 新增。详见 LICENSE / NOTICE。
# 用法：在 fork 仓库根目录打开 PowerShell，执行  powershell -ExecutionPolicy Bypass -File .\build-dist.ps1
[CmdletBinding()]
param(
    [string]$OutputDir = ".\dist-zip",
    [string]$ZipName = "inkos-local-1.7.0"
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path ".").Path

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  InkOS 本地分发包构建脚本" -ForegroundColor Cyan
Write-Host "  仓库根: $RepoRoot" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# 1. 校验 pnpm
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "[错误] 未检测到 pnpm。" -ForegroundColor Red
    Write-Host "请先安装 Node.js 20+ 和 pnpm 9+。安装: npm i -g pnpm" -ForegroundColor Red
    exit 1
}

# 2. 安装依赖
Write-Host "[1/4] 安装依赖..." -ForegroundColor Yellow
pnpm install --frozen-lockfile
if ($LASTEXITCODE -ne 0) { throw "pnpm install 失败" }

# 3. 构建 core
Write-Host "[2/4] 构建 @actalk/inkos-core..." -ForegroundColor Yellow
pnpm --filter @actalk/inkos-core build
if ($LASTEXITCODE -ne 0) { throw "core build 失败" }

# 4. 构建 cli
Write-Host "[3/4] 构建 @actalk/inkos..." -ForegroundColor Yellow
pnpm --filter @actalk/inkos build
if ($LASTEXITCODE -ne 0) { throw "cli build 失败" }

# 5. 准备分发目录（自包含：跳过 pnpm 的虚拟存储，用 npm install 拉平依赖）
Write-Host "[4/4] 打包分发目录（自包含）..." -ForegroundColor Yellow
$StageDir = Join-Path $OutputDir "stage"
if (Test-Path $StageDir) { Remove-Item $StageDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $StageDir | Out-Null

# 5.1 在 stage 中准备 package.json（npm 兼容，让 npm install 生成扁平 node_modules）
#     直接复用 cli 的 package.json，去掉 devDependencies / scripts / type:module 之外的其它
#     pnpm 相关字段。
$SrcCliPkg = Get-Content (Join-Path $RepoRoot "packages\cli\package.json") -Raw | ConvertFrom-Json
$DistPkg = [ordered]@{
    name        = "@actalk/inkos"
    version     = "1.7.0"
    description = $SrcCliPkg.description
    type        = "module"
    bin         = @{ "inkos" = "dist/index.js" }
    dependencies = $SrcCliPkg.dependencies
    license     = "AGPL-3.0-only"
}
$DistPkgJson = $DistPkg | ConvertTo-Json -Depth 10
$DistPkgJson | Set-Content -Path (Join-Path $StageDir "package.json") -Encoding UTF8

# 5.2 把 cli 的 dist 拷到 stage
Copy-Item -Recurse -Force (Join-Path $RepoRoot "packages\cli\dist") (Join-Path $StageDir "dist")

# 5.3 在 stage 中用 npm install 生成扁平 node_modules（npm 比 pnpm 部署更"扁平"，
#     产物不需要 pnpm 运行时解析，搬到任何机器都能直接 require/import）
Write-Host "  正在用 npm install 生成扁平 node_modules..." -ForegroundColor DarkCyan
Push-Location $StageDir
try {
    # --omit=dev 跳过 devDependencies，--no-audit 加快速度
    npm install --omit=dev --no-audit --no-fund --loglevel=error 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    if ($LASTEXITCODE -ne 0) { throw "npm install 失败" }
} finally {
    Pop-Location
}

# 5.4 补回 monorepo 的 @actalk/inkos-core（npm install 找不到 workspace 包，需要手动补）
$CoreDeployDir = Join-Path $StageDir "node_modules\@actalk\inkos-core"
if (Test-Path $CoreDeployDir) { Remove-Item $CoreDeployDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $CoreDeployDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $RepoRoot "packages\core\dist")   (Join-Path $CoreDeployDir "dist")
Copy-Item -Recurse -Force (Join-Path $RepoRoot "packages\core\genres") (Join-Path $CoreDeployDir "genres")
Copy-Item -Force (Join-Path $RepoRoot "packages\core\package.json")   (Join-Path $CoreDeployDir "package.json")
# 同步核心版本号，避免 require('@actalk/inkos-core/package.json') 时拿到错误版本
(Get-Content (Join-Path $CoreDeployDir "package.json") -Raw | ConvertFrom-Json) | ForEach-Object {
    $_.version = "1.7.0"
    $_ | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $CoreDeployDir "package.json") -Encoding UTF8
}

# 5.5 删除 npm install 带来的无关文件（用直接路径，避免 Get-ChildItem -Recurse 在 5 万文件 node_modules 上极慢）
$pathsToDelete = @(
    (Join-Path $StageDir "package-lock.json"),
    (Join-Path $StageDir ".package-lock.json"),
    (Join-Path $StageDir "node_modules\.cache")
)
foreach ($p in $pathsToDelete) {
    if (Test-Path $p) {
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  清理: $p" -ForegroundColor DarkGray
    }
}

# 5.6 补充启动脚本和合规文件
foreach ($item in @("启动 InkOS.bat", "start.sh", "start.command", ".env.example")) {
    $src = Join-Path $RepoRoot $item
    if (Test-Path $src) {
        $dst = Join-Path $StageDir $item
        Copy-Item -Force $src $dst
    } else {
        Write-Host "  [警告] 源文件不存在，跳过: $item" -ForegroundColor DarkYellow
    }
}

# 5.6b 复制 scripts/launch.js（让 启动 InkOS.bat 能找到跨平台启动器）
$scriptsDeployDir = Join-Path $StageDir "scripts"
if (-not (Test-Path $scriptsDeployDir)) { New-Item -ItemType Directory -Force -Path $scriptsDeployDir | Out-Null }
Copy-Item -Force (Join-Path $RepoRoot "scripts\launch.js") (Join-Path $scriptsDeployDir "launch.js")

# 5.6c 复制 runtime/（便携 Node.js，让买家在 Windows 上零依赖启动）
$runtimeDeployDir = Join-Path $StageDir "runtime"
if (Test-Path (Join-Path $RepoRoot "runtime")) {
    if (-not (Test-Path $runtimeDeployDir)) { New-Item -ItemType Directory -Force -Path $runtimeDeployDir | Out-Null }
    $runtimeSize = (Get-ChildItem (Join-Path $RepoRoot "runtime") -Recurse -File | Measure-Object -Property Length -Sum).Sum
    Write-Host "  复制 runtime/ (便携 Node.js，约 $([math]::Round($runtimeSize/1MB, 2)) MB)..." -ForegroundColor DarkCyan
    # 单独复制每个子目录的内容，避免源 runtime/ 顶层污染
    foreach ($sub in Get-ChildItem (Join-Path $RepoRoot "runtime") -Directory -Force) {
        $subName = $sub.Name
        $subDst = Join-Path $runtimeDeployDir $subName
        if (-not (Test-Path $subDst)) { New-Item -ItemType Directory -Force -Path $subDst | Out-Null }
        Get-ChildItem $sub.FullName -Force | ForEach-Object {
            Copy-Item -Force $_.FullName (Join-Path $subDst $_.Name)
        }
    }
    # 复制 runtime/ 顶层文件（如果存在，比如 README）
    Get-ChildItem (Join-Path $RepoRoot "runtime") -File -Force | ForEach-Object {
        Copy-Item -Force $_.FullName (Join-Path $runtimeDeployDir $_.Name)
    }
} else {
    Write-Host "  [警告] 未找到 runtime/ 目录，跳过便携 Node.js 打包" -ForegroundColor DarkYellow
}

# 5.7 写入 LICENSE / NOTICE / README
foreach ($item in @("LICENSE", "NOTICE", "README.分发.md")) {
    $src = Join-Path $RepoRoot $item
    if (Test-Path $src) {
        Copy-Item -Force $src (Join-Path $StageDir $item)
    } else {
        Write-Host "  [警告] 源文件不存在，跳过: $item" -ForegroundColor DarkYellow
    }
}

# 5.8 写入解压说明
$readmeFirst = @"
# 解压后第一步

1. 解压本压缩包到任意目录（推荐纯英文路径，例如 `D:\inkos-local`）
2. 双击 `启动 InkOS.bat`（macOS 用户双击 `start.command`，Linux 用户运行 `./start.sh`）
3. 浏览器自动或手动打开 http://localhost:4567
4. 在 Studio 里点「模型配置」填入你的 LLM API Key
5. 开始创作

完整使用说明：见 `README.分发.md`
许可证 / 源码：见 `LICENSE` 和 `NOTICE`
"@
Set-Content -Path (Join-Path $StageDir "README-先看这个.txt") -Value $readmeFirst -Encoding UTF8

# 6. 压缩
$zipPath = Join-Path $OutputDir "$ZipName.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $StageDir "*") -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  构建完成！" -ForegroundColor Green
Write-Host "  分发包: $zipPath" -ForegroundColor Green
$size = (Get-Item $zipPath).Length
Write-Host "  大小:   $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "下一步：" -ForegroundColor Cyan
Write-Host "  1. 把这个 zip 上传到小红书 / 网盘" -ForegroundColor Cyan
Write-Host "  2. 笔记里挂上下载链接 + NOTICE 里的源码仓库 URL" -ForegroundColor Cyan
Write-Host "  3. 自己解压到临时目录测一次再发布" -ForegroundColor Cyan
