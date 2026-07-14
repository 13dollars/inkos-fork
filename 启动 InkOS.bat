@echo off
chcp 65001 >nul
title InkOS 本地工作台
echo ========================================
echo   InkOS 本地工作台
echo   启动后请用浏览器访问: http://localhost:4567
echo   关闭本窗口即可停止服务
echo ========================================
echo.

where node >nul 2>nul
if errorlevel 1 (
    echo [错误] 未检测到 Node.js。
    echo 请先安装 Node.js 20 或更高版本: https://nodejs.org/
    echo 安装完成后重新双击本文件。
    pause
    exit /b 1
)

node --version
echo.
echo 正在启动 InkOS...
echo.

node "%~dp0scripts\launch.js" %*

echo.
echo InkOS 已退出。
pause
