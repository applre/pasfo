# Pasfo

macOS 菜单栏工具，自动检测剪贴板内容格式并转换为 Apple Notes / Obsidian 友好的富文本。

## 技术栈

- Swift 6 (语言模式 v5) + SwiftUI
- macOS 14+ (Sonoma)
- Swift Package Manager (无第三方依赖)
- 菜单栏应用 (MenuBarExtra, LSUIElement)

## 项目结构

```
Sources/pasfo/
  App.swift                  # 入口，MenuBarExtra + AppDelegate
  Clipboard/
    ClipboardReader.swift    # 读取 NSPasteboard (text/html)
    ClipboardWatcher.swift   # 监视剪贴板变化，跟踪来源 app
    ClipboardWriter.swift    # 写回 HTML/纯文本到剪贴板
  Detection/
    DetectedFormat.swift     # 格式枚举 + ConvertAction 定义
    FormatDetector.swift     # 根据文本内容检测格式类型
    SegmentDetector.swift    # 段落级别的格式检测
  Conversion/
    MarkdownConverter.swift      # Markdown -> HTML
    BoxDrawingConverter.swift    # 制表符表格 -> HTML/Markdown
    TerminalMixedConverter.swift # 终端混合输出 -> HTML
    CodeHighlighter.swift        # 代码 -> 带高亮 HTML
    HTMLToMarkdownConverter.swift # HTML -> Markdown
    HTMLEscaping.swift           # HTML 转义工具
  Views/
    ContentView.swift    # 主界面 (预览 + 转换按钮)
    ConvertButton.swift  # 转换操作按钮组件
    FormatBadge.swift    # 格式标签显示
    PreviewView.swift    # 剪贴板内容预览
Tests/pasfoTests/
  FormatDetectorTests.swift
  BoxDrawingConverterTests.swift
  MarkdownConverterTests.swift
```

## 支持的格式检测与转换

| 检测格式 | 转换目标 |
|---------|---------|
| boxDrawingTable (制表符表格) | HTML / Markdown Table |
| markdownTable | HTML |
| markdownMixed | HTML |
| html | Markdown |
| terminalMixed (终端输出) | HTML |
| codeSnippet | 语法高亮 HTML |
| plainText | 无转换 |

## 常用命令

```bash
# 构建
swift build              # Debug 构建
swift build -c release   # Release 构建

# 运行
make debug               # 构建 + 打包 .app + 打开
make run                 # Release 构建 + 运行

# 测试
swift test               # 运行测试
make test                # 同上

# 清理
make clean

# 安装到 /Applications
make install
```

## 开发注意

- Bundle ID: `com.jingyu.pasfo`
- 应用以 `.accessory` 模式运行（不显示 Dock 图标）
- 使用 `.module` bundle 加载本地化字符串
- 资源文件在 `Sources/pasfo/Resources/`
- Info.plist 在 `Resources/Info.plist`（项目根目录）
