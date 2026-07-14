#!/usr/bin/env bash
# InkOS 一键启动（macOS 双击）
# 来源：本 fork 新增，详见 LICENSE / NOTICE。
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"
bash "$DIR/start.sh"
