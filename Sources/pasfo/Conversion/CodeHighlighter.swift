import Foundation

/// 代码 → 语法高亮 HTML（简单关键词高亮，无外部依赖）
struct CodeHighlighter {
    /// 将代码转换为带简单语法高亮的 HTML
    static func toHTML(_ code: String, language: String = "") -> String {
        let escaped = code.escapingHTMLAttribute()
        let highlighted = applyHighlighting(escaped, language: language)

        let html = """
        <pre style="background:#1e1e1e;color:#d4d4d4;padding:16px;border-radius:8px;font-family:'SF Mono',Menlo,monospace;font-size:13px;line-height:1.5;overflow-x:auto;">\(highlighted)</pre>
        """
        return BoxDrawingConverter.wrapInHTML(html)
    }

    /// 将代码转为纯文本（去除 ANSI 转义等）
    static func toPlainText(_ code: String) -> String {
        ANSICleaner.clean(code)
    }

    private static func applyHighlighting(_ code: String, language: String) -> String {
        var result = code

        // 字符串高亮 (绿色)
        result = result.replacingOccurrences(
            of: #"(&quot;[^&]*?&quot;|'[^']*?')"#,
            with: "<span style=\"color:#ce9178;\">$1</span>",
            options: .regularExpression)

        // 注释高亮 (灰绿) - (?m) 使 $ 匹配每行末尾
        result = result.replacingOccurrences(
            of: #"(?m)(//.*?)$"#,
            with: "<span style=\"color:#6a9955;\">$1</span>",
            options: .regularExpression)
        result = result.replacingOccurrences(
            of: #"(?m)(#.*?)$"#,
            with: "<span style=\"color:#6a9955;\">$1</span>",
            options: .regularExpression)

        // 关键词高亮 (蓝色)
        let keywords = [
            "func", "def", "class", "struct", "enum", "protocol", "extension",
            "import", "from", "return", "if", "else", "for", "while", "switch",
            "case", "break", "continue", "let", "var", "const", "pub", "fn",
            "async", "await", "try", "catch", "throw", "self", "super",
            "true", "false", "nil", "null", "undefined", "None",
            "static", "private", "public", "internal", "override",
        ]
        for keyword in keywords {
            result = result.replacingOccurrences(
                of: "\\b(\(keyword))\\b",
                with: "<span style=\"color:#569cd6;\">$1</span>",
                options: .regularExpression)
        }

        // 数字高亮 (浅绿)
        result = result.replacingOccurrences(
            of: #"\b(\d+\.?\d*)\b"#,
            with: "<span style=\"color:#b5cea8;\">$1</span>",
            options: .regularExpression)

        return result
    }

}

/// ANSI 转义符清理
struct ANSICleaner {
    static func clean(_ text: String) -> String {
        // Remove ANSI escape sequences: ESC[...m, ESC[...H, ESC[...J, etc.
        text.replacingOccurrences(
            of: #"\x1B\[[0-9;]*[a-zA-Z]"#,
            with: "",
            options: .regularExpression)
        .replacingOccurrences(
            of: #"\x1B\][^\x07]*\x07"#,
            with: "",
            options: .regularExpression)
    }
}
