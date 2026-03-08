import AppKit

struct ClipboardWriter {
    /// 写入 HTML + 纯文本到剪贴板（双类型，Apple Notes 读 HTML，其他 App 读 string）
    static func writeHTML(_ html: String, fallbackText: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let htmlData = html.data(using: .utf8) {
            pasteboard.setData(htmlData, forType: .html)
        }
        pasteboard.setString(fallbackText, forType: .string)
    }

    /// 仅写入纯文本
    static func writeText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
