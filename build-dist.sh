#!/usr/bin/env bash
# InkOS 本地分发包构建脚本（bash 版）
# 来源：本 fork 新增。详见 LICENSE / NOTICE。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${1:-./dist-zip}"
ZIP_NAME="inkos-local-1.7.0"

echo "============================================"
echo "  InkOS 本地分发包构建脚本"
echo "  仓库根: $REPO_ROOT"
echo "============================================"

command -v pnpm >/dev/null 2>&1 || { echo "[错误] 未检测到 pnpm"; exit 1; }

echo "[1/4] pnpm install..."
pnpm install --frozen-lockfile

echo "[2/4] pnpm build core..."
pnpm --filter @actalk/inkos-core build

echo "[3/4] pnpm build cli..."
pnpm --filter @actalk/inkos build

echo "[4/4] 打包分发目录（自包含）..."
STAGE_DIR="$OUTPUT_DIR/stage"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

# 4.1 在 stage 中准备 package.json（npm 兼容）
SRC_CLI_PKG="$REPO_ROOT/packages/cli/package.json"
node -e "
const fs = require('fs');
const src = JSON.parse(fs.readFileSync('$SRC_CLI_PKG', 'utf8'));
const dist = {
    name: '@actalk/inkos',
    version: '1.7.0',
    description: src.description,
    type: 'module',
    bin: { inkos: 'dist/index.js' },
    dependencies: src.dependencies,
    license: 'AGPL-3.0-only',
};
fs.writeFileSync('$STAGE_DIR/package.json', JSON.stringify(dist, null, 2));
"

# 4.2 把 cli 的 dist 拷到 stage
cp -R "$REPO_ROOT/packages/cli/dist" "$STAGE_DIR/dist"

# 4.3 用 npm install 生成扁平 node_modules
echo "  正在用 npm install 生成扁平 node_modules..."
cd "$STAGE_DIR"
npm install --omit=dev --no-audit --no-fund --loglevel=error
cd "$REPO_ROOT"

# 4.4 补回 @actalk/inkos-core
CORE_DEPLOY_DIR="$STAGE_DIR/node_modules/@actalk/inkos-core"
rm -rf "$CORE_DEPLOY_DIR"
mkdir -p "$CORE_DEPLOY_DIR"
cp -R "$REPO_ROOT/packages/core/dist" "$CORE_DEPLOY_DIR/dist"
cp -R "$REPO_ROOT/packages/core/genres" "$CORE_DEPLOY_DIR/genres"
cp "$REPO_ROOT/packages/core/package.json" "$CORE_DEPLOY_DIR/package.json"
# 同步核心版本号
node -e "
const fs = require('fs');
const p = '$CORE_DEPLOY_DIR/package.json';
const j = JSON.parse(fs.readFileSync(p, 'utf8'));
j.version = '1.7.0';
fs.writeFileSync(p, JSON.stringify(j, null, 2));
"

# 4.5 删除无关文件
rm -f "$STAGE_DIR/package-lock.json"
rm -rf "$STAGE_DIR/node_modules/.cache" 2>/dev/null

# 4.6 补充启动脚本和合规文件
for f in "启动 InkOS.bat" "start.sh" "start.command" ".env.example" "LICENSE" "NOTICE" "README.分发.md"; do
    [ -e "$REPO_ROOT/$f" ] && cp "$REPO_ROOT/$f" "$STAGE_DIR/$f" || echo "  [警告] 源文件不存在: $f"
done

# 4.7 复制 scripts/launch.js
mkdir -p "$STAGE_DIR/scripts"
cp "$REPO_ROOT/scripts/launch.js" "$STAGE_DIR/scripts/launch.js"

cat > "$STAGE_DIR/README-先看这个.txt" <<'EOF'
# 解压后第一步

1. 解压本压缩包到任意目录（推荐纯英文路径）
2. 双击 `启动 InkOS.bat`（macOS 用户双击 `start.command`，Linux 用户运行 `./start.sh`）
3. 浏览器打开 http://localhost:4567
4. 在 Studio 里点「模型配置」填入你的 LLM API Key
5. 开始创作

完整使用说明：见 `README.分发.md`
许可证 / 源码：见 `LICENSE` 和 `NOTICE`
EOF

cd "$STAGE_DIR"
zip -r "$OUTPUT_DIR/$ZIP_NAME.zip" . -q
cd "$REPO_ROOT"

SIZE=$(du -h "$OUTPUT_DIR/$ZIP_NAME.zip" | cut -f1)
echo ""
echo "============================================"
echo "  构建完成！"
echo "  分发包: $OUTPUT_DIR/$ZIP_NAME.zip"
echo "  大小:   $SIZE"
echo "============================================"
