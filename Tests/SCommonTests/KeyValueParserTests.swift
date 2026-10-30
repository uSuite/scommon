import Testing
@testable import SCommon

struct KeyValueParserTests {
    @Test func skipsCommentsAndBlanks() {
        let text = """
            # comment
              preload   3

            sort date desc
            flag
            """
        let entries = KeyValueParser.parse(text)
        #expect(entries.map(\.key) == ["preload", "sort", "flag"])
        #expect(entries.map(\.value) == ["3", "date desc", ""])
        #expect(entries.map(\.line) == [2, 4, 5])
    }

    @Test func settingReplacesInPlace() {
        let text = "# top\npreload 2\nwrap false\n"
        #expect(KeyValueParser.setting("wrap", to: "true", in: text) == "# top\npreload 2\nwrap true\n")
    }

    @Test func settingIgnoresCommentedKeyAndAppends() {
        let text = "# wrap false\npreload 2\n"
        #expect(KeyValueParser.setting("wrap", to: "true", in: text) == "# wrap false\npreload 2\nwrap true\n")
        #expect(KeyValueParser.setting("a", to: "b", in: "") == "a b\n")
    }
}
