@echo off
REM ============================================================
REM   InkOS 本地工作台 - Windows 启动器
REM
REM   优先使用随包附带的 Node.js 20 portable (runtime\win-x64\node.exe)
REM   仅在 portable 缺失时才查找系统 PATH 里的 node
REM
REM   本文件为本 fork 新增，原始 InkOS 项目无此文件
REM   详见 LICENSE 和 NOTICE
REM ============================================================

chcp 65001 >nul
setlocal
title InkOS 本地工作台

set "RUNTIME_NODE=%~dp0runtime\win-x64\node.exe"
set "NODE_EXE="

echo ========================================
echo   InkOS 本地工作台 v1.7.0
echo   启动后请用浏览器访问: http://localhost:4567
echo   关闭本窗口即可停止服务
echo ========================================
echo.

REM 1. 优先使用本地 portable Node
if exist "%RUNTIME_NODE%" (
    set "NODE_EXE=%RUNTIME_NODE%"
    echo [OK] 使用随包附带的 Node.js
    echo      %RUNTIME_NODE%
) else (
    REM 2. 回退到系统 PATH
    where node >nul 2>nul
    if errorlevel 1 (
        echo [错误] 未检测到 Node.js，且无 portable Node。
        echo 请确认分发包完整（runtime\win-x64\node.exe 必须存在）。
        echo 或者安装 Node.js 20 或更高版本: https://nodejs.org/
        echo.
        pause
        exit /b 1
    )
    set "NODE_EXE=node"
    echo [OK] 使用系统已装 Node.js
)

echo.
echo 当前解压路径: %~dp0
echo 注意：路径含中文或空格可能导致启动失败，建议解压到纯英文目录
echo.
echo Node 版本信息:
"%NODE_EXE%" --version
echo.
echo 正在启动 InkOS...
echo.

REM 把所有参数透传给 launch.js（支持 . tui / doctor / studio 等子命令）
"%NODE_EXE%" "%~dp0scripts\launch.js" %*

echo.
echo InkOS 已退出。
pause
endlocal
