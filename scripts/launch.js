#!/usr/bin/env node
// InkOS 一键启动器（跨平台 Node 入口）
// 作用：等价于执行 `inkos` CLI（无参数时自动启动 Studio 工作台，监听 4567 端口）。
// 来源：本文件为本 fork 新增，原始 InkOS 项目无此文件。详见 ../LICENSE 和 ../NOTICE。
// 参考：https://github.com/Narcooo/inkos（上游 InkOS，AGPL-3.0）
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(here, "..");

// 自动识别两种目录布局：
//   A. 开发模式：repoRoot/packages/cli/dist/index.js 存在
//   B. 分发模式：repoRoot/dist/index.js 存在（pnpm deploy 输出）
const candidates = [
	join(repoRoot, "packages", "cli", "dist", "index.js"),
	join(repoRoot, "dist", "index.js"),
];

let cliEntry = null;
for (const candidate of candidates) {
	if (existsSync(candidate)) {
		cliEntry = candidate;
		break;
	}
}

if (!cliEntry) {
	console.error("[InkOS] 错误：未找到构建产物");
	console.error("[InkOS] 已检查以下位置：");
	for (const candidate of candidates) {
		console.error("  - " + candidate);
	}
	console.error("[InkOS] 解决方案：");
	console.error("  - 开发者：在仓库根目录执行 pnpm install && pnpm build");
	console.error("  - 买家：请用 build-dist 脚本重新生成分发包");
	process.exit(1);
}

const child = spawn(process.execPath, [cliEntry, ...process.argv.slice(2)], {
	stdio: "inherit",
	cwd: process.cwd(),
});

child.on("exit", (code, signal) => {
	if (signal) {
		process.kill(process.pid, signal);
	} else {
		process.exit(code ?? 0);
	}
});

const shutdown = (signal) => {
	if (!child.killed) child.kill(signal);
};
process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
