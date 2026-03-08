import Foundation

struct BoxDrawingConverter {
    /// Box-drawing 表格 → HTML table
    static func toHTML(_ text: String) -> String {
        let rows = parseBoxDrawingTable(text)
        guard !rows.isEmpty else { return wrapInHTML(text) }

        var html = "<table style=\"border-collapse:collapse;\">\n"
        for (index, row) in rows.enumerated() {
            html += "  <tr>\n"
            let tag = index == 0 ? "th" : "td"
            let style = index == 0
                ? "style=\"border:1px solid #ccc;padding:6px 12px;background:#f5f5f5;font-weight:600;\""
                : "style=\"border:1px solid #ccc;padding:6px 12px;\""
            for cell in row {
                html += "    <\(tag) \(style)>\(escapeHTML(cell))</\(tag)>\n"
            }
            html += "  </tr>\n"
        }
        html += "</table>"
        return wrapInHTML(html)
    }

    /// Box-drawing 表格 → Markdown table
    static func toMarkdown(_ text: String) -> String {
        let rows = parseBoxDrawingTable(text)
        guard !rows.isEmpty else { return text }

        let colCount = rows.map(\.count).max() ?? 0
        guard colCount > 0 else { return text }

        // 计算每列最大宽度
        var widths = [Int](repeating: 3, count: colCount)
        for row in rows {
            for (i, cell) in row.enumerated() where i < colCount {
                widths[i] = max(widths[i], cell.count)
            }
        }

        var lines: [String] = []
        for (index, row) in rows.enumerated() {
            let paddedCells = (0..<colCount).map { i in
                let cell = i < row.count ? row[i] : ""
                return cell.padding(toLength: widths[i], withPad: " ", startingAt: 0)
            }
            lines.append("| " + paddedCells.joined(separator: " | ") + " |")

            // 在第一行后添加分隔行
            if index == 0 {
                let separators = widths.map { String(repeating: "-", count: $0) }
                lines.append("| " + separators.joined(separator: " | ") + " |")
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Parser

    /// 解析 box-drawing 表格，提取每行每列的文本内容。
    /// 关键：两条分隔线之间的多个物理行属于同一个逻辑行，需要合并。
    static func parseBoxDrawingTable(_ text: String) -> [[String]] {
        let lines = text.components(separatedBy: .newlines)
        var rows: [[String]] = []
        // 当前逻辑行内积累的物理行
        var currentCells: [String]? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if isBorderLine(trimmed) {
                // 遇到分隔线 → flush 当前积累的逻辑行
                if let cells = currentCells {
                    rows.append(cells)
                    currentCells = nil
                }
                continue
            }

            // 提取这一物理行的 cell 内容
            let cells = extractCells(trimmed)
            guard !cells.isEmpty else { continue }

            if var accumulated = currentCells, accumulated.count == cells.count {
                // 判断是续行还是新行：有空 cell → 续行，全部非空 → 新行
                let hasEmptyCell = cells.contains { $0.trimmingCharacters(in: .whitespaces).isEmpty }
                if hasEmptyCell {
                    // 续行 → 将非空 cell 拼接到对应位置
                    for (i, cell) in cells.enumerated() {
                        let trimmedCell = cell.trimmingCharacters(in: .whitespaces)
                        guard !trimmedCell.isEmpty else { continue }
                        if accumulated[i].trimmingCharacters(in: .whitespaces).isEmpty {
                            accumulated[i] = trimmedCell
                        } else {
                            accumulated[i] = accumulated[i] + " " + trimmedCell
                        }
                    }
                    currentCells = accumulated
                } else {
                    // 新行 → flush 旧行，开始新行
                    rows.append(accumulated)
                    currentCells = cells
                }
            } else {
                // 新逻辑行开始（flush 旧的）
                if let prev = currentCells {
                    rows.append(prev)
                }
                currentCells = cells
            }
        }

        // flush 最后一行
        if let cells = currentCells {
            rows.append(cells)
        }

        return rows
    }

    /// 判断是否为纯边框行
    private static func isBorderLine(_ line: String) -> Bool {
        let stripped = line.unicodeScalars.filter { scalar in
            // 保留非 box-drawing、非空格、非 +、非 - 字符
            let v = scalar.value
            let isBoxDrawing = (0x2500...0x257F).contains(v) || (0x2550...0x256C).contains(v)
            let isBorderChar = scalar == "+" || scalar == "-" || scalar == "=" || scalar == " "
            return !isBoxDrawing && !isBorderChar
        }
        return stripped.isEmpty
    }

    /// 从数据行中提取单元格内容
    private static func extractCells(_ line: String) -> [String] {
        // 将 box-drawing 竖线替换为标准 |
        var normalized = ""
        for scalar in line.unicodeScalars {
            let v = scalar.value
            // │ ║ ┃ and variants
            if v == 0x2502 || v == 0x2503 || v == 0x2551 ||
               (0x2524...0x252B).contains(v) || // ┤ variants
               (0x251C...0x2523).contains(v) || // ├ variants
               (0x2560...0x256C).contains(v) {  // ╠ ╣ etc
                normalized.append("|")
            } else {
                normalized.append(Character(scalar))
            }
        }

        // 按 | 分割并去除首尾空 cell
        let parts = normalized.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // 去除首尾空元素
        var cells = Array(parts)
        if let first = cells.first, first.isEmpty { cells.removeFirst() }
        if let last = cells.last, last.isEmpty { cells.removeLast() }

        return cells.isEmpty ? [] : cells
    }

    // MARK: - Helpers

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    static func wrapInHTML(_ body: String) -> String {
        """
        <html><head><meta charset="utf-8"></head><body style="font-family:-apple-system,sans-serif;font-size:14px;">\(body)</body></html>
        """
    }
}
