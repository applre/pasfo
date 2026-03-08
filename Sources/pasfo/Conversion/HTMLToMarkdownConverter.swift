import Foundation

/// HTML → Markdown 转换器（简单实现，覆盖常见 HTML 标签）
struct HTMLToMarkdownConverter {
    static func convert(_ html: String) -> String {
        var text = html

        // Remove <head>...</head>
        text = text.replacingOccurrences(of: #"<head[^>]*>[\s\S]*?</head>"#, with: "", options: .regularExpression)

        // Headers
        for level in 1...6 {
            let prefix = String(repeating: "#", count: level)
            text = text.replacingOccurrences(
                of: "<h\(level)[^>]*>(.*?)</h\(level)>",
                with: "\(prefix) $1\n",
                options: .regularExpression)
        }

        // Bold
        text = text.replacingOccurrences(of: #"<strong[^>]*>(.*?)</strong>"#, with: "**$1**", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<b[^>]*>(.*?)</b>"#, with: "**$1**", options: .regularExpression)

        // Italic
        text = text.replacingOccurrences(of: #"<em[^>]*>(.*?)</em>"#, with: "*$1*", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<i[^>]*>(.*?)</i>"#, with: "*$1*", options: .regularExpression)

        // Inline code
        text = text.replacingOccurrences(of: #"<code[^>]*>(.*?)</code>"#, with: "`$1`", options: .regularExpression)

        // Code blocks
        text = text.replacingOccurrences(
            of: #"<pre[^>]*><code[^>]*>([\s\S]*?)</code></pre>"#,
            with: "```\n$1\n```",
            options: .regularExpression)
        text = text.replacingOccurrences(
            of: #"<pre[^>]*>([\s\S]*?)</pre>"#,
            with: "```\n$1\n```",
            options: .regularExpression)

        // Links
        text = text.replacingOccurrences(
            of: #"<a[^>]*href="([^"]*)"[^>]*>(.*?)</a>"#,
            with: "[$2]($1)",
            options: .regularExpression)

        // Images
        text = text.replacingOccurrences(
            of: #"<img[^>]*src="([^"]*)"[^>]*alt="([^"]*)"[^>]*/?\s*>"#,
            with: "![$2]($1)",
            options: .regularExpression)

        // List items
        text = text.replacingOccurrences(of: #"<li[^>]*>(.*?)</li>"#, with: "- $1", options: .regularExpression)

        // Remove list wrappers
        text = text.replacingOccurrences(of: #"</?[uo]l[^>]*>"#, with: "", options: .regularExpression)

        // Blockquote
        text = text.replacingOccurrences(of: #"<blockquote[^>]*>(.*?)</blockquote>"#, with: "> $1", options: .regularExpression)

        // Horizontal rule
        text = text.replacingOccurrences(of: #"<hr[^>]*/?\s*>"#, with: "---\n", options: .regularExpression)

        // Line breaks / paragraphs
        text = text.replacingOccurrences(of: #"<br[^>]*/?\s*>"#, with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<p[^>]*>(.*?)</p>"#, with: "$1\n", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<div[^>]*>(.*?)</div>"#, with: "$1\n", options: .regularExpression)

        // Tables (basic)
        text = convertHTMLTable(text)

        // Strip remaining tags
        text = text.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)

        // Decode HTML entities
        text = decodeHTMLEntities(text)

        // Clean up excessive newlines
        text = text.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        return text
    }

    private static func convertHTMLTable(_ html: String) -> String {
        var result = html
        // Simple table extraction: find <table>...</table> and convert rows
        let tablePattern = #"<table[^>]*>([\s\S]*?)</table>"#
        guard let regex = try? NSRegularExpression(pattern: tablePattern) else { return result }

        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
        for match in matches.reversed() {
            guard let tableRange = Range(match.range, in: result),
                  let contentRange = Range(match.range(at: 1), in: result) else { continue }

            let tableContent = String(result[contentRange])
            let mdTable = tableHTMLToMarkdown(tableContent)
            result.replaceSubrange(tableRange, with: mdTable)
        }

        return result
    }

    private static func tableHTMLToMarkdown(_ html: String) -> String {
        let rowPattern = #"<tr[^>]*>([\s\S]*?)</tr>"#
        guard let rowRegex = try? NSRegularExpression(pattern: rowPattern) else { return html }

        let cellPattern = #"<t[hd][^>]*>([\s\S]*?)</t[hd]>"#
        guard let cellRegex = try? NSRegularExpression(pattern: cellPattern) else { return html }

        let rowMatches = rowRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        var rows: [[String]] = []

        for rowMatch in rowMatches {
            guard let contentRange = Range(rowMatch.range(at: 1), in: html) else { continue }
            let rowContent = String(html[contentRange])

            let cellMatches = cellRegex.matches(in: rowContent, range: NSRange(rowContent.startIndex..., in: rowContent))
            let cells = cellMatches.compactMap { cellMatch -> String? in
                guard let cellRange = Range(cellMatch.range(at: 1), in: rowContent) else { return nil }
                return String(rowContent[cellRange])
                    .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            rows.append(cells)
        }

        guard !rows.isEmpty else { return html }

        var lines: [String] = []
        for (index, row) in rows.enumerated() {
            lines.append("| " + row.joined(separator: " | ") + " |")
            if index == 0 {
                let sep = row.map { _ in "---" }
                lines.append("| " + sep.joined(separator: " | ") + " |")
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func decodeHTMLEntities(_ text: String) -> String {
        text.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}
