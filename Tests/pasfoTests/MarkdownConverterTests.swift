import Testing
@testable import pasfo

@Suite("MarkdownConverter")
struct MarkdownConverterTests {

    @Test("标题转换")
    func headers() {
        let md = "# Hello\n## World"
        let html = MarkdownConverter.toHTML(md)
        #expect(html.contains("<h1"))
        #expect(html.contains("Hello"))
        #expect(html.contains("<h2"))
        #expect(html.contains("World"))
    }

    @Test("粗体转换")
    func bold() {
        let result = MarkdownConverter.renderInline("This is **bold** text")
        #expect(result.contains("<strong>bold</strong>"))
    }

    @Test("斜体转换")
    func italic() {
        let result = MarkdownConverter.renderInline("This is *italic* text")
        #expect(result.contains("<em>italic</em>"))
    }

    @Test("行内代码转换")
    func inlineCode() {
        let result = MarkdownConverter.renderInline("Use `code` here")
        #expect(result.contains("<code"))
        #expect(result.contains("code"))
    }

    @Test("链接转换")
    func links() {
        let result = MarkdownConverter.renderInline("[Google](https://google.com)")
        #expect(result.contains("<a href=\"https://google.com\""))
        #expect(result.contains("Google"))
    }

    @Test("无序列表")
    func unorderedList() {
        let md = "- Item 1\n- Item 2\n- Item 3"
        let html = MarkdownConverter.toHTML(md)
        #expect(html.contains("<ul"))
        #expect(html.contains("<li>"))
        #expect(html.contains("Item 1"))
    }

    @Test("有序列表")
    func orderedList() {
        let md = "1. First\n2. Second\n3. Third"
        let html = MarkdownConverter.toHTML(md)
        #expect(html.contains("<ol"))
        #expect(html.contains("<li>"))
        #expect(html.contains("First"))
    }

    @Test("代码块")
    func codeBlock() {
        let md = "```swift\nlet x = 1\n```"
        let html = MarkdownConverter.toHTML(md)
        #expect(html.contains("<pre"))
        #expect(html.contains("<code>"))
        #expect(html.contains("let x = 1"))
    }

    @Test("Markdown 表格")
    func table() {
        let md = """
        | Name | Age |
        |------|-----|
        | Alice | 30 |
        | Bob   | 25 |
        """
        let html = MarkdownConverter.toHTML(md)
        #expect(html.contains("<table"))
        #expect(html.contains("Alice"))
        #expect(html.contains("30"))
    }

    @Test("引用块")
    func blockquote() {
        let md = "> This is a quote"
        let html = MarkdownConverter.toHTML(md)
        #expect(html.contains("<blockquote"))
        #expect(html.contains("This is a quote"))
    }

    @Test("终端 wrap 截断的表格行能正确合并（不以 | 结尾）")
    func wrappedTableRowsNoTrailingPipe() {
        // 终端 wrap 导致行尾没有 |
        let md = """
        | 模块 | 文件 | 功能 |
        |------|------|------|
        | App 入口 | App.swift | MenuBarExtra 菜单栏图标 + 浮动面板，无
        Dock 图标 |
        | 格式检测 | FormatDetector.swift | 5 种格式自动检测 |
        """
        let html = MarkdownConverter.toHTML(md)
        let trCount = html.components(separatedBy: "<tr>").count - 1
        #expect(trCount == 3) // header + 2 data rows
        #expect(html.contains("Dock"))
    }

    @Test("终端 wrap 续行合并（每行都有完整 | 分隔）")
    func continuationRowMerging() {
        // 终端 wrap 但每行都是完整的 | 格式，续行大部分 cell 为空
        let md = """
        | 模块 | 文件 | 功能 |
        |------|------|------|
        | Box-drawing | BoxDrawingConverter.swift | Unicode 表格 → HTML table / Markdown |
        | 转换 |  | table |
        | Markdown 转换 | MarkdownConverter.swift | Markdown → Apple Notes HTML |
        """
        let html = MarkdownConverter.toHTML(md)
        let trCount = html.components(separatedBy: "<tr>").count - 1
        #expect(trCount == 3) // header + 2 data rows, "转换" merged into Box-drawing row
        #expect(html.contains("Box-drawing 转换"))
        #expect(html.contains("Markdown table"))
    }

    @Test("续行合并 - 多列续行")
    func continuationRowMultiColumn() {
        let md = """
        | Name | File | Description |
        |------|------|------|
        | Markdown 转换 | MarkdownConverter.swi | Markdown → Apple Notes HTML (headers, |
        |  | ft | bold, lists, tables, code blocks) |
        """
        let html = MarkdownConverter.toHTML(md)
        let trCount = html.components(separatedBy: "<tr>").count - 1
        #expect(trCount == 2) // header + 1 data row
        #expect(html.contains("MarkdownConverter.swi ft"))
        #expect(html.contains("code blocks)"))
    }

    @Test("混合内容")
    func mixedContent() {
        let md = """
        # Report

        Some **important** text with `code`.

        - Item 1
        - Item 2

        | Col1 | Col2 |
        |------|------|
        | A    | B    |
        """
        let html = MarkdownConverter.toHTML(md)
        #expect(html.contains("<h1"))
        #expect(html.contains("<strong>important</strong>"))
        #expect(html.contains("<ul"))
        #expect(html.contains("<table"))
    }
}

@Suite("HTMLToMarkdownConverter")
struct HTMLToMarkdownConverterTests {

    @Test("基本 HTML 转 Markdown")
    func basicConversion() {
        let html = "<h1>Title</h1><p>Hello <strong>world</strong></p>"
        let md = HTMLToMarkdownConverter.convert(html)
        #expect(md.contains("# Title"))
        #expect(md.contains("**world**"))
    }

    @Test("链接转换")
    func links() {
        let html = "<a href=\"https://example.com\">Example</a>"
        let md = HTMLToMarkdownConverter.convert(html)
        #expect(md.contains("[Example](https://example.com)"))
    }
}

@Suite("ANSICleaner")
struct ANSICleanerTests {

    @Test("清理 ANSI 转义符")
    func cleanANSI() {
        let input = "\u{1B}[31mRed text\u{1B}[0m and \u{1B}[1;32mgreen bold\u{1B}[0m"
        let cleaned = ANSICleaner.clean(input)
        #expect(cleaned == "Red text and green bold")
    }

    @Test("纯文本不受影响")
    func plainTextUnchanged() {
        let input = "Hello, world!"
        #expect(ANSICleaner.clean(input) == input)
    }
}
