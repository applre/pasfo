# 剪贴板格式研究 - 各应用复制行为分析

> 调研时间：2026-03-08
> 用途：了解不同来源的剪贴板格式，确保 Pasfo 的格式检测覆盖所有主流场景

---

## 核心结论

| 规律 | 应用 |
|------|------|
| 大部分 GUI 应用都是 HTML | 浏览器、富文本编辑器、通讯工具、电子表格 |
| 终端永远是纯文本 | Terminal、iTerm2、Warp，靠内容特征区分格式 |
| Copy 按钮通常是 Markdown | ChatGPT、Claude 的 Copy 按钮给的是 Markdown 源码 |
| 代码编辑器看应用 | VS Code/JetBrains 给 HTML（带高亮），Xcode/Sublime 给纯文本 |

---

## 详细分析

### AI 工具

| 应用 | 复制方式 | 剪贴板格式 | Pasfo 检测 |
|------|---------|-----------|-------------------|
| ChatGPT 网页 | 选中文字 Cmd+C | HTML | HTML / Rich Text |
| ChatGPT 网页 | 点 Copy 按钮 | Markdown 纯文本 | Markdown 混合内容 |
| Claude 网页 | 选中文字 Cmd+C | HTML | HTML / Rich Text |
| Claude 网页 | 点 Copy 按钮 | Markdown 纯文本 | Markdown 混合内容 |
| Claude Code (终端) | 选中文字 Cmd+C | 纯文本（可能含 box-drawing、ANSI） | Box-drawing / Markdown / 终端混合 / 代码 |

### 终端

| 应用 | 复制方式 | 剪贴板格式 | Pasfo 检测 |
|------|---------|-----------|-------------------|
| Terminal.app | Cmd+C | 纯文本（含 ANSI 转义符） | 按内容判断 |
| iTerm2 | Cmd+C | 纯文本（含 ANSI 转义符） | 按内容判断 |
| Warp | Cmd+C | 纯文本 | 按内容判断 |
| Warp | 点代码块 Copy 按钮 | 纯文本（更干净，无 ANSI） | 按内容判断 |

终端复制内容的实际格式取决于输出内容本身：

| 终端输出内容 | 检测结果 |
|------------|---------|
| `docker ps`、`kubectl get` 等制表符表格 | Box-drawing 表格 |
| Claude Code 的 Markdown 回复 | Markdown 混合内容 |
| 命令 + 表格 + diff 混合 | 终端混合内容 |
| `cat main.swift` 等代码输出 | 代码片段 |
| 普通命令输出 | 纯文本 |

### 浏览器

| 应用 | 复制方式 | 剪贴板格式 | Pasfo 检测 |
|------|---------|-----------|-------------------|
| Safari | 选中文字 Cmd+C | HTML + 纯文本 | HTML / Rich Text |
| Chrome | 选中文字 Cmd+C | HTML + 纯文本 | HTML / Rich Text |
| GitHub 网页 | 选中文字 Cmd+C | HTML | HTML / Rich Text |
| GitHub 网页 | 点代码块 Copy 按钮 | 纯文本 | 代码片段 / 纯文本 |

### 笔记 / 文档

| 应用 | 复制方式 | 剪贴板格式 | Pasfo 检测 |
|------|---------|-----------|-------------------|
| Apple Notes | Cmd+C | HTML（富文本） | HTML / Rich Text |
| Notion | Cmd+C | HTML + 纯文本 | HTML / Rich Text |
| Notion | 右键 → Copy as Markdown | Markdown 纯文本 | Markdown 混合内容 |
| Obsidian | Cmd+C | Markdown 纯文本 | Markdown 混合 / Markdown 表格 |
| Bear | Cmd+C | HTML + 纯文本 | HTML / Rich Text |
| Typora | Cmd+C | HTML + 纯文本 | HTML / Rich Text |
| Google Docs | Cmd+C | HTML | HTML / Rich Text |

### 编辑器 / IDE

| 应用 | 复制方式 | 剪贴板格式 | Pasfo 检测 |
|------|---------|-----------|-------------------|
| VS Code | Cmd+C | HTML + 纯文本（带语法高亮 HTML） | HTML / Rich Text |
| Xcode | Cmd+C | 纯文本 | 代码片段 |
| JetBrains IDE | Cmd+C | HTML + 纯文本（带高亮） | HTML / Rich Text |
| Vim/Neovim (终端) | 终端选中复制 | 纯文本 | 代码片段 |
| Sublime Text | Cmd+C | 纯文本 | 代码片段 |

### 通讯 / 协作

| 应用 | 复制方式 | 剪贴板格式 | Pasfo 检测 |
|------|---------|-----------|-------------------|
| Slack | Cmd+C | HTML + 纯文本 | HTML / Rich Text |
| 微信 | Cmd+C | HTML + 纯文本 | HTML / Rich Text |
| 飞书 | Cmd+C | HTML + 纯文本 | HTML / Rich Text |
| 邮件 (Mail.app) | Cmd+C | HTML + 纯文本 | HTML / Rich Text |
| 企业微信 | Cmd+C | HTML + 纯文本 | HTML / Rich Text |

### 电子表格

| 应用 | 复制方式 | 剪贴板格式 | Pasfo 检测 |
|------|---------|-----------|-------------------|
| Excel | Cmd+C | HTML（`<table>`）+ 纯文本 | HTML / Rich Text |
| Numbers | Cmd+C | HTML（`<table>`）+ 纯文本 | HTML / Rich Text |
| Google Sheets | Cmd+C | HTML（`<table>`）+ 纯文本 | HTML / Rich Text |

---

## 对 Pasfo 的启示

1. **HTML 是最常见的剪贴板格式** — 大部分 GUI 应用复制时都会在剪贴板放 HTML 类型，检测 HTML pasteboard 类型作为最高优先级是正确的
2. **终端是唯一纯文本来源** — 需要靠内容特征（box-drawing、Markdown 语法、代码模式）做二次检测
3. **AI 工具的 Copy 按钮是 Markdown** — 这是高频场景，Markdown → Apple Notes HTML 的转换质量至关重要
4. **VS Code / JetBrains 给 HTML** — 从这些编辑器复制代码时，剪贴板已经是带高亮的 HTML，直接粘贴到 Apple Notes 就有格式，不需要额外转换
5. **Xcode / Sublime 给纯文本** — 从这些编辑器复制代码时，需要 Pasfo 的代码高亮功能
