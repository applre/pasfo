import Foundation

/// 终端混合内容 -> Apple Notes HTML
struct TerminalMixedConverter {

    static func toHTML(_ text: String) -> String {
        let segments = SegmentDetector.split(text)
        let parts = segments.map { renderSegment($0) }
        let body = parts.joined(separator: "\n<div style=\"margin:8px 0;\"></div>\n")
        return BoxDrawingConverter.wrapInHTML(body)
    }

    private static func renderSegment(_ segment: Segment) -> String {
        switch segment.format {
        case .boxDrawingTable:
            return renderBoxTable(segment.text)
        case .diff:
            return renderDiff(segment.text)
        case .tree:
            return renderPre(segment.text)
        case .columnTable:
            return renderColumnTable(segment.text)
        case .json:
            return renderPre(segment.text)
        case .keyValue:
            return renderKeyValue(segment.text)
        case .code:
            return renderCode(segment.text)
        case .shellCommand:
            return renderShellCommand(segment.text)
        case .text:
            return renderText(segment.text)
        }
    }

    // MARK: - Renderers

    private static func renderBoxTable(_ text: String) -> String {
        let rows = BoxDrawingConverter.parseBoxDrawingTable(text)
        guard !rows.isEmpty else { return renderPre(text) }
        return renderHTMLTable(rows)
    }

    private static func renderColumnTable(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let rows = lines.map { SegmentDetector.splitColumns($0) }
        guard !rows.isEmpty else { return renderPre(text) }
        return renderHTMLTable(rows)
    }

    private static func renderHTMLTable(_ rows: [[String]]) -> String {
        var html = "<table style=\"border-collapse:collapse;width:100%;\">\n"
        for (i, row) in rows.enumerated() {
            html += "  <tr>\n"
            let tag = i == 0 ? "th" : "td"
            let bg = i == 0 ? "background:#f5f5f5;font-weight:600;" : ""
            for cell in row {
                html += "    <\(tag) style=\"border:1px solid #ccc;padding:6px 12px;\(bg)\">\(cell.escapingHTML())</\(tag)>\n"
            }
            html += "  </tr>\n"
        }
        html += "</table>"
        return html
    }

    private static func renderDiff(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let rendered = lines.map { line -> String in
            let t = line.trimmingCharacters(in: .whitespaces)
            let escaped = line.escapingHTML()
            if t.hasPrefix("+++") || t.hasPrefix("---") {
                return "<div style=\"color:#888;\">\(escaped)</div>"
            } else if t.hasPrefix("+") {
                return "<div style=\"background:#e6ffed;color:#22863a;\">\(escaped)</div>"
            } else if t.hasPrefix("-") {
                return "<div style=\"background:#ffeef0;color:#cb2431;\">\(escaped)</div>"
            } else if t.hasPrefix("@@") {
                return "<div style=\"color:#6f42c1;\">\(escaped)</div>"
            } else {
                return "<div>\(escaped)</div>"
            }
        }
        return """
        <pre style="background:#f8f8f8;padding:12px;border-radius:6px;font-family:'SF Mono',Menlo,monospace;font-size:13px;line-height:1.4;overflow-x:auto;">\(rendered.joined())</pre>
        """
    }

    private static func renderKeyValue(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var rows: [[String]] = []
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if let colonRange = t.range(of: #"[:=]\s+"#, options: .regularExpression) {
                let key = String(t[t.startIndex..<colonRange.lowerBound])
                let value = String(t[colonRange.upperBound...])
                rows.append([key, value])
            } else {
                rows.append([t, ""])
            }
        }

        var html = "<table style=\"border-collapse:collapse;\">\n"
        for row in rows {
            html += "  <tr>\n"
            html += "    <td style=\"border:1px solid #ccc;padding:6px 12px;font-weight:600;background:#f5f5f5;white-space:nowrap;\">\(row[0].escapingHTML())</td>\n"
            if row.count > 1 {
                html += "    <td style=\"border:1px solid #ccc;padding:6px 12px;\">\(row[1].escapingHTML())</td>\n"
            }
            html += "  </tr>\n"
        }
        html += "</table>"
        return html
    }

    private static func renderCode(_ text: String) -> String {
        let escaped = text.escapingHTML()
        return """
        <pre style="background:#1e1e1e;color:#d4d4d4;padding:12px;border-radius:6px;font-family:'SF Mono',Menlo,monospace;font-size:13px;line-height:1.4;overflow-x:auto;">\(escaped)</pre>
        """
    }

    private static func renderShellCommand(_ text: String) -> String {
        let escaped = text.escapingHTML()
        return """
        <p style="margin:4px 0;"><code style="background:#f0f0f0;padding:2px 6px;border-radius:3px;font-family:'SF Mono',Menlo,monospace;font-size:13px;">\(escaped)</code></p>
        """
    }

    private static func renderPre(_ text: String) -> String {
        let escaped = text.escapingHTML()
        return """
        <pre style="background:#f5f5f5;padding:12px;border-radius:6px;font-family:'SF Mono',Menlo,monospace;font-size:13px;line-height:1.4;overflow-x:auto;">\(escaped)</pre>
        """
    }

    private static func renderText(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        return lines.map { "<p style=\"margin:4px 0;\">\($0.escapingHTML())</p>" }.joined(separator: "\n")
    }

}
