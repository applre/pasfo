# 调研报告：Markdown 粘贴到 Apple Notes 工具现状

> 调研时间：2026-03-07
> 调研方法：WebSearch 多轮

---

## 一、结论速览

| 现有方案 | 类型 | 能否"粘贴 MD → 渲染" | 局限 |
|---|---|---|---|
| iOS/macOS 26 原生 | 系统内置 | 文件导入（非剪贴板粘贴） | 尚未正式发布 |
| Apple Shortcuts 内置 shortcut | 系统工具 | ✅ 剪贴板 MD → Notes | macOS 上链接不可点击 |
| ProNotes | Mac App | ❌（是实时 Markdown 输入，非粘贴转换） | 只支持行首语法触发 |
| Drafts App Action | 第三方 App | ✅ 但创建新笔记，非粘贴到现有 | 需要 Drafts App，Mac only |
| Pandoc + 脚本 | CLI | ✅ 批量迁移 | 手动操作，无 UI |
| Marked 2 | 付费 Mac App | ✅ 转 RTFD 后导入 | 多步骤，非一键 |

**核心结论**：目前没有一个工具能做到"复制 MD → 一键粘贴为渲染格式到 Apple Notes"的流畅体验。最接近的是 Apple 内置 Shortcut，但有 macOS 上的 bug（链接不可点击）。

---

## 二、详细现状分析

### 2.1 iOS 26 / macOS 26 原生支持（最大新闻）

Apple 在 iOS 26（Tahoe，预计 2026 年 9 月正式发布）中为 Notes 添加了 Markdown 导入/导出：

- **导入**：File → Import to Notes，选 `.md` 文件，自动转为富文本（保留标题、列表、链接、粗体等）
- **导出**：File → Export as Markdown
- **限制**：是**文件级别**的操作，不是"剪贴板粘贴"；Notes 编辑界面仍然是富文本，不显示 MD 语法

📌 参考：[MacRumors：iOS 26 Markdown Import/Export](https://www.macrumors.com/how-to/ios-import-export-markdown-apple-notes/)

---

### 2.2 Apple Shortcuts 内置 Shortcut："Clipboard Markdown to Notes"

这是**目前最接近你需求**的现有方案：

- 在 Shortcuts Gallery 可直接获取
- 流程：复制 MD 文本 → 运行 Shortcut → 自动转成富文本创建到 Apple Notes
- **已知 bug**：iOS/iPadOS 上链接可点击，macOS Sequoia 上超链接**不可点击**（需手动修复）

📌 参考：[Apple Community 讨论](https://discussions.apple.com/thread/256066936)

---

### 2.3 ProNotes（免费 Mac App）

- 本质：Apple Notes 的"Markdown 输入助手"，**不是转换粘贴工具**
- 支持在 Notes 中用 `#` `##` `[]` ` ``` ` `>` 等语法实时触发格式，类似 Notion 的 slash commands
- **不解决"粘贴已有 MD 文本"的需求**
- 免费，macOS 13+

📌 参考：[ProNotes 官网](https://www.pronotes.app/) | [Geeky Gadgets 评测](https://www.geeky-gadgets.com/apple-notes-markdown-support/)

---

### 2.4 Drafts App "Markdown to Notes" Action

- 在 Drafts Directory 有一个 Action：将 Drafts 中的 MD 文本转成 HTML，再用 AppleScript 创建 Apple Notes 笔记
- **缺点**：需要 Drafts App，只支持 Mac，而且是创建新笔记，不是粘贴到已有笔记

📌 参考：[Drafts Directory Action](https://actions.getdrafts.com/a/16g)

---

### 2.5 Pandoc + 脚本批量迁移

- 适合从 Obsidian 等迁移大量 MD 文件到 Apple Notes
- 流程：Pandoc 转 HTML → 通过 AppleScript 批量导入
- **不适合"粘贴单条"的日常使用场景**

📌 参考：[Salar Rahmanian 的 Obsidian → Apple Notes 迁移文章](https://www.softinio.com/til/migrating-my-markdown-notes-from-obsidian-to-apple-notes/)

---

### 2.6 Apple Notes 本身的 Markdown 限制

即使工具能转换，Apple Notes 对某些格式支持有限：

| 格式 | 支持情况 |
|---|---|
| 标题 H1-H3 | ✅ |
| 粗体、斜体 | ✅ |
| 无序/有序列表 | ✅ |
| 链接 | ✅（但 macOS Shortcut 有 bug）|
| 代码块（monospace）| ✅ iOS 17+ |
| 语法高亮 | ❌ |
| 表格 | ❌（完全不支持）|
| 图片（外链） | ❌ |

---

## 三、市场空缺分析

你想做的工具——**"复制 MD 文本 → 一键粘贴为渲染富文本到 Apple Notes"**，目前没有完美的现成工具：

1. Apple 原生 Shortcut 方案有 macOS bug（链接不可点击）
2. ProNotes 是输入助手，不是粘贴转换
3. Drafts 依赖额外 App，且只创建新笔记
4. iOS 26 的原生支持是文件导入，不是剪贴板流

**潜在实现路径**（仅供参考）：

- **macOS App/Menu Bar Tool**：监听热键或菜单栏按钮，读剪贴板 MD，用 `NSAttributedString` 或 Pandoc 转 HTML，再通过 AppleScript/JXA 写入 Apple Notes
- **Apple Shortcut 改进版**：修复链接可点击问题，并可选择目标笔记本/已有笔记
- **Swift CLI**：命令行读 stdin MD，写入 Notes（适合开发者）

---

## 四、相关 GitHub 项目参考

- [Kylmakalle/apple-notes-exporter](https://github.com/Kylmakalle/apple-notes-exporter) — Notes → MD（反向）
- [mgooley/apple-notes-to-markdown-shortcut](https://github.com/mgooley/apple-notes-to-markdown-shortcut) — Notes → MD（反向）
- [KrauseFx/notes-exporter](https://github.com/KrauseFx/notes-exporter) — Ruby 直接读 SQLite
- [jhuckaby/clipdown](https://github.com/jhuckaby/clipdown) — HTML → MD 剪贴板转换（反向）

目前 GitHub 上**没有**叫 `pasfo` 或 "markdown to apple notes" 的专门工具项目。

---

## 五、原始搜索索引

| 查询 | 来源 |
|------|------|
| markdown to Apple Notes converter tool 2025 2026 | WebSearch |
| paste markdown Apple Notes app mac tool | WebSearch |
| markdown Apple Notes clipboard paste shortcut macOS GitHub/Reddit | WebSearch |
| pasfo cli tool github | WebSearch |
| ProNotes app Apple Notes markdown formatting 2025 | WebSearch |
| apple shortcut "markdown to notes" clipboard convert paste rich text | WebSearch |
| apple notes markdown import limitations code block table | WebSearch |
