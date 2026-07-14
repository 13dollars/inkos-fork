#!/usr/bin/env bash
# InkOS 一键启动（Linux 终端）
# 来源：本 fork 新增，详见 LICENSE / NOTICE。
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "  InkOS 本地工作台"
echo "  启动后请用浏览器访问: http://localhost:4567"
echo "  按 Ctrl+C 即可停止服务"
echo "========================================"
echo

if ! command -v node >/dev/null 2>&1; then
    echo "[错误] 未检测到 Node.js。"
    echo "请先安装 Node.js 20 或更高版本: https://nodejs.org/"
    exit 1
fi

echo "Node 版本: $(node --version)"
echo
echo "正在启动 InkOS..."
echo

node "$SCRIPT_DIR/scripts/launch.js" "$@"
