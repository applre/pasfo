

# Pasfo

macOS 菜单栏工具，自动检测剪贴板内容格式并转换为 Apple Notes / Obsidian 友好的富文本（主要是终端文本）。

## 功能

- 自动检测剪贴板中的内容格式（Markdown、代码、表格、HTML 等）
- 一键转换为适合粘贴到 Apple Notes 或 Obsidian 的格式
- 菜单栏常驻，不占用 Dock 栏
- 监视剪贴板变化，识别来源应用
- 纯本地运行，无需网络，无第三方依赖

## 支持的格式


| 检测格式               | 转换目标               |
| ------------------ | ------------------ |
| 终端混合输出             | 富文本               |
| Markdown（混合/表格）    | 富文本           |
| 制表符表格（Box Drawing） | 富文本 / Markdown 表格 |
| 富文本               | Markdown           |
| 代码片段               | 语法高亮 富文本          |


## 安装

### 下载 DMG

前往 [Releases](https://github.com/applre/pasfo/releases) 下载最新版本，打开 DMG 拖入 Applications 即可。

### 从源码构建

需要 macOS 14+ 和 Swift 6。

```bash
git clone https://github.com/applre/pasfo.git
cd pasfo
make dmg
```

构建产物在 `.build/Pasfo.dmg`。

## 使用

启动后 Pasfo 会出现在菜单栏。复制一段文本后点击菜单栏图标，Pasfo 会自动识别格式并提供转换选项。选择目标格式后，转换结果会自动写入剪贴板，直接粘贴到目标应用即可。

## 技术栈

- Swift 6 + SwiftUI
- macOS 14+ (Sonoma)
- Swift Package Manager
- 零第三方依赖

## License

[MIT](LICENSE)