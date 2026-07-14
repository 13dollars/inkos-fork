# InkOS 本地工作台（小红书分发版）

> 这是基于开源项目 [InkOS](https://github.com/Narcooo/inkos) 的**本地一键启动版**。
> 严格遵循 AGPL-3.0 开源协议，详情见本目录 `LICENSE` 和 `NOTICE` 文件。
> 本作品**不修改 InkOS 任何功能**，只新增了一键启动入口。

---

## 启动方式

### Windows 用户
1. 解压本压缩包到任意目录（**路径不要有中文**更稳妥）
2. **双击 `启动 InkOS.bat`**
3. 弹出黑色窗口，看到 `InkOS 本地工作台` 字样即启动成功
4. 打开浏览器访问 http://localhost:4567
5. 用完直接关闭黑色窗口即可停止服务

> 如果双击后提示"未检测到 Node.js"，请先安装 [Node.js 20 或更高版本](https://nodejs.org/)。

### macOS 用户
1. 解压本压缩包
2. **双击 `start.command`**
3. 第一次会提示"无法打开，因为它来自身份不明的开发者"
4. 打开 `系统设置 → 隐私与安全`，点击底部"仍要打开"按钮
5. 之后双击即可正常打开终端
6. 浏览器访问 http://localhost:4567

### Linux 用户
```bash
chmod +x start.sh
./start.sh
# 然后浏览器打开 http://localhost:4567
```

---

## 第一次使用：配置 LLM Key

启动后浏览器会进入 InkOS Studio：

1. 点击左侧「**模型配置**」
2. 选择服务商（Google Gemini / Moonshot Kimi / MiniMax / 智谱 / DeepSeek / 自定义 等）
3. 粘贴你的 API Key
4. 点击「**测试连接**」，看到绿色 ✅ 即成功
5. 选择默认模型，保存
6. 回到「**开始创作**」开始写小说

> 没有 API Key？先在对应服务商官网注册账号，充值 / 申请免费额度后获取 Key。

---

## 常见操作速查

| 想做的事 | 怎么做 |
|---|---|
| 创建第一本书 | Studio → 开始创作 → 长篇小说 → 填标题/题材/章节字数 |
| 写下一章 | Studio → 选中书 → 「写下一章」按钮 |
| 命令行 | 同一个目录里新开终端，跑 `node scripts/launch.js --help` |
| 修改启动端口 | `node scripts/launch.js --port 4568`（部分命令支持） |
| 看全部命令 | `node scripts/launch.js` 会启动 Studio，看 Studio 顶部"帮助" |
| 出错了 | 看终端黑窗口的错误信息，或看 `inkos.log` |

---

## 源码 / 二次开发

本作品完整源代码、修改 diff、AGPL 合规说明见 `NOTICE` 文件的"完整对应源码"章节。

上游项目：[https://github.com/Narcooo/inkos](https://github.com/Narcooo/inkos)

---

## 致谢

- **上游项目**：[InkOS](https://github.com/Narcooo/inkos) © Narcooo，AGPL-3.0
- **底层依赖**：[pi-mono](https://github.com/badlogic/pi-mono) © Mario Zechner
- **本作品**：基于上述开源项目改造，AGPL-3.0

---

## 免责声明

本作品按"原样"提供，不提供任何明示或暗示的担保。
使用本作品产生的任何数据安全、创作内容、账号问题等风险由使用者自行承担。
上游 InkOS 项目及其贡献者不对本衍生作品提供支持。
