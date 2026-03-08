import Testing
@testable import pasfo

@Suite("FormatDetector")
struct FormatDetectorTests {

    @Test("检测 box-drawing 表格")
    func detectBoxDrawing() {
        let input = """
        ┌──────────┬──────────┬──────────┐
        │ Column 1 │ Column 2 │ Column 3 │
        ├──────────┼──────────┼──────────┤
        │ data 1   │ data 2   │ data 3   │
        └──────────┴──────────┴──────────┘
        """
        #expect(FormatDetector.detect(input) == .boxDrawingTable)
    }

    @Test("检测双线 box-drawing 表格")
    func detectDoubleBoxDrawing() {
        let input = """
        ╔══════════╦══════════╗
        ║ Header 1 ║ Header 2 ║
        ╠══════════╬══════════╣
        ║ Cell 1   ║ Cell 2   ║
        ╚══════════╩══════════╝
        """
        #expect(FormatDetector.detect(input) == .boxDrawingTable)
    }

    @Test("检测 Markdown 表格")
    func detectMarkdownTable() {
        let input = """
        | Name | Age | City |
        |------|-----|------|
        | Alice | 30 | NYC |
        | Bob  | 25 | LA   |
        """
        #expect(FormatDetector.detect(input) == .markdownTable)
    }

    @Test("检测 Markdown 混合内容")
    func detectMarkdownMixed() {
        let input = """
        # Title

        Some **bold** text and a [link](https://example.com).

        - List item 1
        - List item 2

        ```
        code block
        ```
        """
        #expect(FormatDetector.detect(input) == .markdownMixed)
    }

    @Test("检测代码片段")
    func detectCodeSnippet() {
        let input = """
        func hello() {
            let name = "World"
            print("Hello, \\(name)")
            return
        }
        """
        #expect(FormatDetector.detect(input) == .codeSnippet)
    }

    @Test("检测纯文本")
    func detectPlainText() {
        let input = "Just a simple sentence without any special formatting."
        #expect(FormatDetector.detect(input) == .plainText)
    }

    @Test("检测 HTML（通过剪贴板类型）")
    func detectHTMLFromPasteboard() {
        let input = "<p>Hello world</p>"
        #expect(FormatDetector.detect(input, hasHTMLPasteboard: true) == .html)
    }

    @Test("空文本返回 plainText")
    func detectEmpty() {
        #expect(FormatDetector.detect("") == .plainText)
        #expect(FormatDetector.detect("   ") == .plainText)
    }
}
