import Foundation

extension String {
    /// 转义 HTML 特殊字符 (& < >)
    func escapingHTML() -> String {
        self.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// 转义 HTML 特殊字符，含双引号 (用于 HTML 属性值)
    func escapingHTMLAttribute() -> String {
        escapingHTML()
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
