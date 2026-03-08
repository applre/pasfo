# Use Cases - Pasfo

macOS 菜单栏剪贴板格式转换工具，自动检测剪贴板内容格式并转换，主要服务于 Apple Notes 粘贴场景。

## 格式自动检测规则

### 一级格式（整体检测）

检测优先级从上到下，命中第一个即返回。

| # | 格式类型 | 检测规则 |
|---|---------|---------|
| 1 | HTML / Rich Text | 剪贴板包含 HTML pasteboard 类型 |
| 2 | 终端混合内容 | 按空行分段后有 2+ 种不同格式，且至少一段为终端特有格式 |
| 3 | Box-drawing 表格 | 包含 4+ 个 Unicode 制表符（`┌ ┬ ┐ │ ├ ┼ ┤ └ ┴ ┘`，U+2500~U+257F） |
| 4 | Markdown 表格 | 存在分隔行匹配 `\|---\|---\|` |
| 5 | Markdown 混合内容 | `#` 标题、`**` 粗体、`-` 列表、`` ``` `` 代码块、`[]()`链接等特征评分 >= 3 |
| 6 | 代码片段 | 代码关键词/缩进/花括号等特征占比 > 40% 且 >= 3 行 |
| 7 | 纯文本 | 以上规则均不匹配 |

### 二级格式（终端混合内容的段落子格式）

终端混合内容按空行分段后，每段独立检测：

| # | 段落类型 | 检测规则 | 渲染方式 |
|---|---------|---------|---------|
| 1 | Shell 命令 | 单行以 `$ ` 或 `% ` 开头 | `<code>` 行内等宽 |
| 2 | Box-drawing 表格 | 含 4+ 个 Unicode 制表符 | `<table>` HTML 表格 |
| 3 | Diff 输出 | 有 `@@`/`diff`/`---`/`+++` 头部，或同时有 `+` 和 `-` 行 | 带颜色 `<pre>`（绿增红删） |
| 4 | 目录树 | 含 `├──` `└──` `│` 等 tree 字符 | `<pre>` 等宽块 |
| 5 | 列式输出 | 2+ 列空格对齐，且列数跨行一致 | `<table>` HTML 表格 |
| 6 | JSON | 以 `{` 或 `[` 开头且对应闭合 | `<pre>` 等宽块 |
| 7 | Key-Value | 50%+ 的行匹配 `Key: Value` 或 `Key= Value` | `<table>` 两列表格 |
| 8 | 代码 | 代码关键词/缩进/花括号特征 | `<pre>` 深色背景等宽块 |
| 9 | 普通文本 | 兜底 | `<p>` 段落 |

### 每种格式的可用操作

| 格式 | 操作 1（推荐） | 操作 2 |
|------|--------------|--------|
| HTML / Rich Text | → Markdown | → 纯文本 |
| 终端混合内容 | → Apple Notes（分段转 HTML） | → 纯文本 |
| Box-drawing 表格 | → Apple Notes（HTML table） | → Markdown 表格 |
| Markdown 表格 | → Apple Notes（HTML table） | → 纯文本 |
| Markdown 混合内容 | → Apple Notes（HTML） | → 清理 ANSI |
| 代码片段 | → Apple Notes（语法高亮 HTML） | → 纯文本 |
| 纯文本 | 无操作 | — |

---

## Use Case 一览

### UC-1: 终端 Box-drawing 表格 → Apple Notes

**场景**: 从 Claude Code 终端复制带 Unicode 边框的表格

| 项目 | 内容 |
|------|------|
| 来源 App | Terminal / iTerm2 / Warp (Claude Code 输出) |
| 剪贴板原始格式 | Unicode box-drawing 表格 (`┌─┬─┐ │ ├─┼─┤ └─┴─┘`) |
| 自动检测结果 | Box-drawing Table |
| 转换方式 | → Rich Text (HTML `<table>`) 写入剪贴板 |
| 目标 App | Apple Notes |
| 粘贴效果 | 原生可编辑表格，行列完整保留 |

**示例输入：**
```
┌──────────┬────────────────────────┬──────────────────────┐
│   对比   │    外部 MCP（npx）     │     builtin MCP      │
├──────────┼────────────────────────┼──────────────────────┤
│ 启动方式 │ spawn 子进程           │ 内存中直接调用       │
└──────────┴────────────────────────┴──────────────────────┘
```

**转换后剪贴板内容 (HTML)：**
```html
<table>
  <tr><th>对比</th><th>外部 MCP（npx）</th><th>builtin MCP</th></tr>
  <tr><td>启动方式</td><td>spawn 子进程</td><td>内存中直接调用</td></tr>
</table>
```

---

### UC-2: 终端 Box-drawing 表格 → Obsidian

**场景**: 从 Claude Code 终端复制表格，粘贴到 Obsidian 笔记

| 项目 | 内容 |
|------|------|
| 来源 App | Terminal / iTerm2 / Warp (Claude Code 输出) |
| 剪贴板原始格式 | Unicode box-drawing 表格 |
| 自动检测结果 | Box-drawing Table |
| 转换方式 | → Markdown 表格 (`\| xx \| xx \|`) |
| 目标 App | Obsidian / Typora |
| 粘贴效果 | 标准 Markdown 表格，正常渲染 |

**转换后剪贴板内容：**
```markdown
| 对比 | 外部 MCP（npx） | builtin MCP |
|------|----------------|-------------|
| 启动方式 | spawn 子进程 | 内存中直接调用 |
```

---

### UC-3: 终端 Markdown 混合内容 → Apple Notes

**场景**: Claude Code 输出了包含标题、列表、代码块、表格的完整 Markdown 回答，想保存到 Apple Notes

| 项目 | 内容 |
|------|------|
| 来源 App | Terminal / iTerm2 / Warp (Claude Code 输出) |
| 剪贴板原始格式 | Markdown 混合内容（`#` 标题 + `- ` 列表 + `` ``` `` 代码块 + `\|` 表格） |
| 自动检测结果 | Markdown Mixed |
| 转换方式 | → Rich Text (HTML) 写入剪贴板 |
| 目标 App | Apple Notes |
| 粘贴效果 | 标题加粗加大、列表有缩进符号、代码有底色块、表格为原生表格 |

**示例输入：**
```
## 安装步骤

- 克隆仓库
- 运行 `bun install`

| 命令 | 用途 |
|------|------|
| dev  | 开发 |
```

**粘贴到 Apple Notes 效果：**
- "安装步骤" 显示为加粗标题
- 列表有缩进和项目符号
- `bun install` 显示为行内代码样式
- 表格为 Apple Notes 原生表格

---

### UC-4: 终端 Markdown 内容 → Obsidian（保持原样）

**场景**: Claude Code 输出的 Markdown 内容想原样保存到 Obsidian

| 项目 | 内容 |
|------|------|
| 来源 App | Terminal / iTerm2 / Warp (Claude Code 输出) |
| 剪贴板原始格式 | Markdown 混合内容 |
| 自动检测结果 | Markdown Mixed |
| 转换方式 | → 保持 Markdown 原文（清理终端 ANSI 转义符） |
| 目标 App | Obsidian / Typora / VS Code |
| 粘贴效果 | 干净的 Markdown 源码，直接渲染 |

**处理细节：**
- 去除 ANSI 颜色/样式转义序列 (`\033[...m`)
- 保留 Markdown 语法不变
- 修正终端换行符差异

---

### UC-5: 网页 Rich Text → Obsidian

**场景**: 从 Notion、网页、邮件等复制富文本内容，想以 Markdown 存入 Obsidian

| 项目 | 内容 |
|------|------|
| 来源 App | Chrome / Safari / Notion / 邮件客户端 |
| 剪贴板原始格式 | Rich Text (HTML) |
| 自动检测结果 | HTML / Rich Text |
| 转换方式 | → Markdown 纯文本 |
| 目标 App | Obsidian / VS Code / 任意文本编辑器 |
| 粘贴效果 | 干净的 Markdown，表格转为 `\|` 语法，标题转为 `#`，列表转为 `-` |

---

### UC-6: 网页 Rich Text → 纯文本

**场景**: 从网页复制内容，想去掉所有格式只保留文字

| 项目 | 内容 |
|------|------|
| 来源 App | Chrome / Safari / Notion / 任意富文本来源 |
| 剪贴板原始格式 | Rich Text (HTML) |
| 自动检测结果 | HTML / Rich Text |
| 转换方式 | → 纯文本（去除所有标签和样式） |
| 目标 App | 任意文本编辑器 / 搜索栏 / 表单输入 |
| 粘贴效果 | 纯文字，无格式 |

---

### UC-7: 代码片段 → Apple Notes（带语法高亮）

**场景**: 从 VS Code 或终端复制代码，想在 Apple Notes 里保存并带高亮

| 项目 | 内容 |
|------|------|
| 来源 App | VS Code / Terminal / 任意编辑器 |
| 剪贴板原始格式 | 代码文本（可能带 `` ``` `` 包裹） |
| 自动检测结果 | Code Snippet |
| 转换方式 | → Rich Text (HTML，带语法高亮样式) |
| 目标 App | Apple Notes / 邮件 |
| 粘贴效果 | 代码块有背景色，关键字有语法着色 |

---

### UC-8: 纯文本（无需转换）

**场景**: 剪贴板内容是普通文字，无特殊格式

| 项目 | 内容 |
|------|------|
| 来源 App | 任意 |
| 剪贴板原始格式 | 纯文本 |
| 自动检测结果 | Plain Text |
| 转换方式 | 无需转换，菜单栏提示"当前为纯文本，无需转换" |
| 目标 App | — |
| 粘贴效果 | — |

---

### UC-9: 终端混合内容 → Apple Notes

**场景**: 从终端复制一大段混合输出（命令 + 表格 + diff + JSON + 目录树等），想整体保存到 Apple Notes 并保持格式

| 项目 | 内容 |
|------|------|
| 来源 App | Terminal / iTerm2 / Warp |
| 剪贴板原始格式 | 终端混合输出（多段不同格式内容） |
| 自动检测结果 | Terminal Mixed |
| 转换方式 | → Rich Text (HTML)，按空行分段，每段独立识别并转为对应 HTML |
| 目标 App | Apple Notes |
| 粘贴效果 | 命令行等宽显示、表格为原生表格、diff 带颜色、目录树保持缩进 |

**示例输入：**
```
$ kubectl get pods

┌───────────┬─────────┬────────┐
│ NAME      │ STATUS  │ AGE    │
├───────────┼─────────┼────────┤
│ nginx-abc │ Running │ 2d     │
└───────────┴─────────┴────────┘

$ git diff

--- a/main.swift
+++ b/main.swift
@@ -1,3 +1,4 @@
 import Foundation
+import SwiftUI
 let x = 1
-let y = 2
+let y = 3

$ cat config.json

{
  "server": {
    "port": 8080,
    "host": "localhost"
  }
}
```

**转换后每段渲染：**
- `$ kubectl get pods` → `<code>` 行内等宽命令
- Box-drawing 表格 → `<table>` HTML 原生表格
- `$ git diff` → `<code>` 行内等宽命令
- diff 输出 → `<pre>` 带颜色（`+` 行绿底，`-` 行红底，`@@` 紫色）
- `$ cat config.json` → `<code>` 行内等宽命令
- JSON → `<pre>` 等宽代码块

---

### UC-10: 终端列式输出 → Apple Notes

**场景**: 从终端复制 `ps aux`、`ls -l`、`brew list` 等空格对齐的列式输出

| 项目 | 内容 |
|------|------|
| 来源 App | Terminal / iTerm2 / Warp |
| 剪贴板原始格式 | 空格对齐的列式文本 |
| 自动检测结果 | Terminal Mixed（当与其他终端格式混合时） |
| 转换方式 | 列式段落 → `<table>` HTML 表格 |
| 目标 App | Apple Notes |
| 粘贴效果 | 原生可编辑表格，首行为表头 |

**示例输入（作为混合内容的一段）：**
```
PID   USER   %CPU  COMMAND
1234  root   2.3   nginx
5678  www    0.1   node
```

**转换后：**
```html
<table>
  <tr><th>PID</th><th>USER</th><th>%CPU</th><th>COMMAND</th></tr>
  <tr><td>1234</td><td>root</td><td>2.3</td><td>nginx</td></tr>
  <tr><td>5678</td><td>www</td><td>0.1</td><td>node</td></tr>
</table>
```

---

### UC-11: 终端 Key-Value 输出 → Apple Notes

**场景**: 从终端复制 `docker inspect`、`systemctl status` 等 Key-Value 格式输出

| 项目 | 内容 |
|------|------|
| 来源 App | Terminal / iTerm2 / Warp |
| 剪贴板原始格式 | Key: Value 格式文本 |
| 自动检测结果 | Terminal Mixed（当与其他终端格式混合时） |
| 转换方式 | Key-Value 段落 → `<table>` 两列表格（Key 列灰底加粗） |
| 目标 App | Apple Notes |
| 粘贴效果 | 两列表格，左列为属性名（加粗灰底），右列为值 |

**示例输入（作为混合内容的一段）：**
```
Name:     nginx
State:    running
IP:       172.17.0.2
Port:     80/tcp
```

**转换后：**
```html
<table>
  <tr><td style="font-weight:600;background:#f5f5f5;">Name</td><td>nginx</td></tr>
  <tr><td style="font-weight:600;background:#f5f5f5;">State</td><td>running</td></tr>
  <tr><td style="font-weight:600;background:#f5f5f5;">IP</td><td>172.17.0.2</td></tr>
  <tr><td style="font-weight:600;background:#f5f5f5;">Port</td><td>80/tcp</td></tr>
</table>
```

---

### UC-12: 终端目录树 → Apple Notes

**场景**: 从终端复制 `tree` 命令输出的目录结构

| 项目 | 内容 |
|------|------|
| 来源 App | Terminal / iTerm2 / Warp |
| 剪贴板原始格式 | tree 命令输出 |
| 自动检测结果 | Terminal Mixed（当与其他终端格式混合时） |
| 转换方式 | tree 段落 → `<pre>` 等宽块，保留缩进和连接线 |
| 目标 App | Apple Notes |
| 粘贴效果 | 等宽字体显示，缩进和 `├──` `└──` 连接线完整保留 |

**示例输入（作为混合内容的一段）：**
```
src/
├── main.swift
├── Views/
│   ├── ContentView.swift
│   └── FormatBadge.swift
└── App.swift
```

---

## 用户交互流程

```
1. 用户在来源 App 复制内容 (Cmd+C)
2. 点击菜单栏图标（或按快捷键，如 Cmd+Shift+V）
3. App 自动检测剪贴板格式，弹出面板显示：
   - 检测到的格式类型（带图标和颜色标签）
   - 内容预览（前几行）
   - 可用的转换选项（根据检测结果智能推荐）
4. 用户点击目标格式按钮，或按键盘 1/2 快速选择
5. 转换完成，剪贴板已更新，提示"已转换为 Rich Text"
6. 面板 1.5 秒后自动关闭
7. 用户去目标 App 粘贴 (Cmd+V)
```

## 优先级

| 优先级 | Use Case | 理由 |
|--------|----------|------|
| P0 | UC-1: Box-drawing → Apple Notes | 核心痛点，最高频场景 |
| P0 | UC-3: Markdown 混合 → Apple Notes | 核心痛点，Claude Code 主要输出格式 |
| P0 | UC-9: 终端混合内容 → Apple Notes | 核心痛点，终端复制的一大段混合输出 |
| P1 | UC-2: Box-drawing → Markdown | Obsidian 用户常见需求 |
| P1 | UC-5: HTML → Markdown | 反向转换，网页→笔记 |
| P1 | UC-10: 列式输出 → Apple Notes | 终端常见输出格式 |
| P1 | UC-11: Key-Value → Apple Notes | 终端常见输出格式 |
| P2 | UC-4: Markdown 清理 | 去 ANSI 转义符 |
| P2 | UC-7: 代码 → 高亮 Rich Text | 锦上添花 |
| P2 | UC-12: 目录树 → Apple Notes | 保持等宽显示 |
| P3 | UC-6: HTML → 纯文本 | 简单功能 |
| P3 | UC-8: 纯文本提示 | 边界情况 |
