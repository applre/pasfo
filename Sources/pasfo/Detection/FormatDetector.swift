import Foundation

struct FormatDetector {
    // Box-drawing characters: ─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬
    private static let boxDrawingRange = Character("\u{2500}")...Character("\u{257F}")
    private static let boxDrawingDoubleRange = Character("\u{2550}")...Character("\u{256C}")

    /// 检测文本格式，按优先级从高到低
    static func detect(_ text: String, hasHTMLPasteboard: Bool = false) -> DetectedFormat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .plainText }

        // 1. 剪贴板含 HTML 类型
        if hasHTMLPasteboard {
            return .html
        }

        // 2. 终端混合内容（多段不同格式）
        if SegmentDetector.isTerminalMixed(trimmed) {
            return .terminalMixed
        }

        // 3. Box-drawing 字符检测
        if containsBoxDrawing(trimmed) {
            return .boxDrawingTable
        }

        // 4. Markdown 表格（含 |---|---| 分隔行）
        if isMarkdownTable(trimmed) {
            return .markdownTable
        }

        // 5. Markdown 混合内容
        if isMarkdownMixed(trimmed) {
            return .markdownMixed
        }

        // 6. 代码片段
        if isCodeSnippet(trimmed) {
            return .codeSnippet
        }

        return .plainText
    }

    /// 检测是否含 box-drawing 字符
    static func containsBoxDrawing(_ text: String) -> Bool {
        let boxCount = text.unicodeScalars.filter { scalar in
            (0x2500...0x257F).contains(scalar.value) || (0x2550...0x256C).contains(scalar.value)
        }.count
        // 至少有几个 box-drawing 字符，且占比合理
        return boxCount >= 4
    }

    /// 检测 Markdown 表格：至少有一行匹配 |---|
    static func isMarkdownTable(_ text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        let separatorPattern = #"^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$"#
        return lines.contains { line in
            line.range(of: separatorPattern, options: .regularExpression) != nil
        }
    }

    /// 检测 Markdown 混合内容
    static func isMarkdownMixed(_ text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        var score = 0

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            // Headers: # ## ###
            if trimmedLine.range(of: #"^#{1,6}\s"#, options: .regularExpression) != nil { score += 2 }
            // Code blocks: ```
            if trimmedLine.hasPrefix("```") { score += 2 }
            // Bold/italic: **text** or *text*
            if trimmedLine.range(of: #"\*\*.+\*\*"#, options: .regularExpression) != nil { score += 1 }
            // Lists: - item or * item or 1. item
            if trimmedLine.range(of: #"^[\-\*]\s"#, options: .regularExpression) != nil { score += 1 }
            if trimmedLine.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil { score += 1 }
            // Links: [text](url)
            if trimmedLine.range(of: #"\[.+\]\(.+\)"#, options: .regularExpression) != nil { score += 1 }
            // Inline code: `code`
            if trimmedLine.range(of: #"`.+`"#, options: .regularExpression) != nil { score += 1 }
        }

        return score >= 3
    }

    /// 检测代码片段
    static func isCodeSnippet(_ text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        var codeIndicators = 0

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            // 缩进（4空格或tab开头）
            if line.hasPrefix("    ") || line.hasPrefix("\t") { codeIndicators += 1 }
            // 常见代码模式
            if trimmedLine.range(of: #"^(func |def |class |import |const |let |var |if |for |while |return |pub |fn )"#, options: .regularExpression) != nil {
                codeIndicators += 2
            }
            // 花括号
            if trimmedLine.contains("{") || trimmedLine.contains("}") { codeIndicators += 1 }
            // 分号结尾
            if trimmedLine.hasSuffix(";") { codeIndicators += 1 }
        }

        let lineCount = max(lines.count, 1)
        return Double(codeIndicators) / Double(lineCount) > 0.4 && lines.count >= 3
    }
}
