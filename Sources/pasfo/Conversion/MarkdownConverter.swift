import Foundation

/// Markdown → HTML 转换器（无外部依赖，覆盖常用 Markdown 语法）
struct MarkdownConverter {
    /// Markdown 文本 → Apple Notes 兼容的 HTML
    static func toHTML(_ markdown: String) -> String {
        let lines = mergeWrappedLines(markdown.components(separatedBy: .newlines))
        var html: [String] = []
        var inCodeBlock = false
        var codeBlockLang = ""
        var codeBlockLines: [String] = []
        var inList = false
        var listType: ListType = .unordered
        var inTable = false
        var tableRows: [[String]] = []
        var tableAlignments: [Alignment] = []

        for line in lines {
            // Code block handling
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    let code = codeBlockLines.joined(separator: "\n")
                    html.append(renderCodeBlock(code, language: codeBlockLang))
                    codeBlockLines = []
                    codeBlockLang = ""
                    inCodeBlock = false
                } else {
                    // Close any open list/table
                    closeList(&html, &inList, listType)
                    closeTable(&html, &inTable, &tableRows, tableAlignments)
                    // Start code block
                    inCodeBlock = true
                    codeBlockLang = String(line.trimmingCharacters(in: .whitespaces).dropFirst(3))
                }
                continue
            }

            if inCodeBlock {
                codeBlockLines.append(line)
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Empty line closes list/table
            if trimmed.isEmpty {
                closeList(&html, &inList, listType)
                closeTable(&html, &inTable, &tableRows, tableAlignments)
                html.append("")
                continue
            }

            // Table: separator line detection
            if isTableSeparator(trimmed) {
                tableAlignments = parseAlignments(trimmed)
                inTable = true
                continue
            }

            // Table: data row (must have | separator)
            if inTable && trimmed.contains("|") {
                let cells = parseTableRow(trimmed)
                tableRows.append(cells)
                continue
            }

            // Potential table start (first row before separator)
            if !inTable && trimmed.contains("|") && !trimmed.hasPrefix("|") == false {
                // Check if next lines form a table - speculatively treat as table header
                let cells = parseTableRow(trimmed)
                if cells.count >= 2 {
                    closeList(&html, &inList, listType)
                    inTable = true
                    tableRows = [cells]
                    continue
                }
            }

            closeTable(&html, &inTable, &tableRows, tableAlignments)

            // Headers
            if let headerMatch = trimmed.range(of: #"^(#{1,6})\s+(.+)$"#, options: .regularExpression) {
                closeList(&html, &inList, listType)
                let content = String(trimmed[headerMatch])
                let level = content.prefix(while: { $0 == "#" }).count
                let text = String(content.dropFirst(level).trimmingCharacters(in: .whitespaces))
                let fontSize = [28, 24, 20, 18, 16, 14][min(level - 1, 5)]
                html.append("<h\(level) style=\"font-size:\(fontSize)px;margin:12px 0 6px;\">\(renderInline(text))</h\(level)>")
                continue
            }

            // Horizontal rule
            if trimmed.range(of: #"^[-*_]{3,}$"#, options: .regularExpression) != nil {
                closeList(&html, &inList, listType)
                html.append("<hr style=\"border:none;border-top:1px solid #ccc;margin:12px 0;\">")
                continue
            }

            // Unordered list
            if trimmed.range(of: #"^[-*+]\s+"#, options: .regularExpression) != nil {
                if !inList || listType != .unordered {
                    closeList(&html, &inList, listType)
                    html.append("<ul style=\"margin:4px 0;padding-left:24px;\">")
                    inList = true
                    listType = .unordered
                }
                let content = String(trimmed.drop(while: { $0 == "-" || $0 == "*" || $0 == "+" || $0 == " " }))
                html.append("  <li>\(renderInline(content))</li>")
                continue
            }

            // Ordered list
            if trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil {
                if !inList || listType != .ordered {
                    closeList(&html, &inList, listType)
                    html.append("<ol style=\"margin:4px 0;padding-left:24px;\">")
                    inList = true
                    listType = .ordered
                }
                let content = String(trimmed.drop(while: { $0.isNumber || $0 == "." || $0 == " " }))
                html.append("  <li>\(renderInline(content))</li>")
                continue
            }

            // Blockquote
            if trimmed.hasPrefix(">") {
                closeList(&html, &inList, listType)
                let content = String(trimmed.dropFirst().trimmingCharacters(in: .whitespaces))
                html.append("<blockquote style=\"border-left:3px solid #ccc;padding-left:12px;margin:8px 0;color:#555;\">\(renderInline(content))</blockquote>")
                continue
            }

            // Regular paragraph
            closeList(&html, &inList, listType)
            html.append("<p style=\"margin:4px 0;\">\(renderInline(trimmed))</p>")
        }

        // Close any remaining open blocks
        closeList(&html, &inList, listType)
        closeTable(&html, &inTable, &tableRows, tableAlignments)

        if inCodeBlock {
            let code = codeBlockLines.joined(separator: "\n")
            html.append(renderCodeBlock(code, language: codeBlockLang))
        }

        let body = html.joined(separator: "\n")
        return BoxDrawingConverter.wrapInHTML(body)
    }

    // MARK: - Inline rendering

    /// 渲染内联 Markdown 语法：bold, italic, code, links, strikethrough
    static func renderInline(_ text: String) -> String {
        var result = escapeHTML(text)
        // Bold: **text** or __text__
        result = result.replacingOccurrences(
            of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>",
            options: .regularExpression)
        result = result.replacingOccurrences(
            of: #"__(.+?)__"#, with: "<strong>$1</strong>",
            options: .regularExpression)
        // Italic: *text* or _text_
        result = result.replacingOccurrences(
            of: #"\*(.+?)\*"#, with: "<em>$1</em>",
            options: .regularExpression)
        result = result.replacingOccurrences(
            of: #"(?<!\w)_(.+?)_(?!\w)"#, with: "<em>$1</em>",
            options: .regularExpression)
        // Strikethrough: ~~text~~
        result = result.replacingOccurrences(
            of: #"~~(.+?)~~"#, with: "<del>$1</del>",
            options: .regularExpression)
        // Inline code: `code`
        result = result.replacingOccurrences(
            of: #"`([^`]+)`"#,
            with: "<code style=\"background:#f0f0f0;padding:1px 4px;border-radius:3px;font-size:13px;\">$1</code>",
            options: .regularExpression)
        // Links: [text](url)
        result = result.replacingOccurrences(
            of: #"\[([^\]]+)\]\(([^)]+)\)"#,
            with: "<a href=\"$2\" style=\"color:#0066cc;\">$1</a>",
            options: .regularExpression)
        return result
    }

    // MARK: - Code block

    private static func renderCodeBlock(_ code: String, language: String) -> String {
        let escaped = escapeHTML(code)
        return """
        <pre style="background:#f5f5f5;padding:12px;border-radius:6px;overflow-x:auto;font-size:13px;line-height:1.4;"><code>\(escaped)</code></pre>
        """
    }

    // MARK: - Table

    private enum Alignment { case left, center, right }
    private enum ListType { case ordered, unordered }

    private static func isTableSeparator(_ line: String) -> Bool {
        line.range(of: #"^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$"#, options: .regularExpression) != nil
    }

    private static func parseAlignments(_ line: String) -> [Alignment] {
        let parts = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        return parts.compactMap { part in
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("-") else { return nil }
            let left = trimmed.hasPrefix(":")
            let right = trimmed.hasSuffix(":")
            if left && right { return .center }
            if right { return .right }
            return .left
        }
    }

    private static func parseTableRow(_ line: String) -> [String] {
        var cells = line.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        if let first = cells.first, first.isEmpty { cells.removeFirst() }
        if let last = cells.last, last.isEmpty { cells.removeLast() }
        return cells
    }

    /// 合并续行：如果一行有空 cell，且与上一行合并后更合理，则视为续行
    /// 终端 wrap 导致的续行特征：列数相同、至少一个 cell 为空
    static func mergeContinuationRows(_ rows: [[String]]) -> [[String]] {
        guard rows.count > 1 else { return rows }
        let expectedColCount = rows[0].count
        guard expectedColCount > 0 else { return rows }

        var merged: [[String]] = []
        for row in rows {
            // 至少有 header+1 行后才考虑续行（不合并到 header）
            if merged.count >= 2, row.count == expectedColCount {
                let emptyCount = row.filter { $0.trimmingCharacters(in: .whitespaces).isEmpty }.count
                // 至少 1 个 cell 为空 → 可能是续行
                if emptyCount >= 1 {
                    var updated = merged.removeLast()
                    for (i, cell) in row.enumerated() {
                        let trimmed = cell.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty, i < updated.count else { continue }
                        if updated[i].trimmingCharacters(in: .whitespaces).isEmpty {
                            updated[i] = trimmed
                        } else {
                            updated[i] = updated[i] + " " + trimmed
                        }
                    }
                    merged.append(updated)
                    continue
                }
            }
            merged.append(row)
        }
        return merged
    }

    private static func closeTable(_ html: inout [String], _ inTable: inout Bool,
                                    _ rows: inout [[String]], _ alignments: [Alignment]) {
        guard inTable, !rows.isEmpty else { return }

        let finalRows = mergeContinuationRows(rows)
        var tableHTML = "<table style=\"border-collapse:collapse;\">\n"
        for (rowIndex, row) in finalRows.enumerated() {
            tableHTML += "  <tr>\n"
            let tag = rowIndex == 0 ? "th" : "td"
            let bgStyle = rowIndex == 0 ? "background:#f5f5f5;font-weight:600;" : ""
            for (colIndex, cell) in row.enumerated() {
                let align = colIndex < alignments.count ? alignments[colIndex] : .left
                let alignStyle: String
                switch align {
                case .left: alignStyle = ""
                case .center: alignStyle = "text-align:center;"
                case .right: alignStyle = "text-align:right;"
                }
                tableHTML += "    <\(tag) style=\"border:1px solid #ccc;padding:6px 12px;\(bgStyle)\(alignStyle)\">\(renderInline(cell))</\(tag)>\n"
            }
            tableHTML += "  </tr>\n"
        }
        tableHTML += "</table>"
        html.append(tableHTML)
        inTable = false
        rows = []
    }

    private static func closeList(_ html: inout [String], _ inList: inout Bool, _ type: ListType) {
        guard inList else { return }
        switch type {
        case .unordered: html.append("</ul>")
        case .ordered: html.append("</ol>")
        }
        inList = false
    }

    // MARK: - Line merging

    /// 合并被终端 wrap 截断的行。
    /// 规则：
    /// 1. Markdown 表格行以 `|` 开头且以 `|` 结尾 → 完整行
    /// 2. 以 `|` 开头但不以 `|` 结尾 → 被截断，后续行合并直到遇到 `|` 结尾
    /// 3. 不以 `|` 开头且前一行是截断的表格行 → 续行，拼接到前一行
    static func mergeWrappedLines(_ lines: [String]) -> [String] {
        var result: [String] = []
        var pending: String? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let accumulated = pending {
                // 正在积累一个截断行
                let joined = accumulated + " " + trimmed
                if trimmed.hasSuffix("|") || trimmed.isEmpty {
                    // 行结束
                    result.append(joined)
                    pending = nil
                } else {
                    pending = joined
                }
            } else if trimmed.hasPrefix("|") && !trimmed.hasSuffix("|") && !isTableSeparator(trimmed) {
                // 截断的表格行：以 | 开头但不以 | 结尾
                pending = trimmed
            } else {
                result.append(line)
            }
        }

        // flush 残留
        if let remaining = pending {
            result.append(remaining)
        }

        return result
    }

    // MARK: - Helpers

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
