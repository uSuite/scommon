import Testing
@testable import SCommon

/// A tiny vocabulary standing in for an app's commands.
enum TestCommand: KeymapCommand {
    case next
    case first
    case last
    case go(Int)

    struct Unknown: Error, CustomStringConvertible {
        let name: String
        var description: String { "unknown command '\(name)'" }
    }

    static func parse(_ text: String) throws -> TestCommand {
        let words = text.split(separator: " ").map(String.init)
        switch (words.first, words.count) {
        case ("next", 1):
            return .next
        case ("first", 1):
            return .first
        case ("last", 1):
            return .last
        case ("go", 2):
            if let n = Int(words[1]) {
                return .go(n)
            }
        default:
            break
        }
        throw Unknown(name: text)
    }
}

struct KeymapGenericTests {
    private typealias Map = Keymap<TestCommand>

    @Test func parsesReportsIssuesAndLaterLinesWin() {
        let (map, issues) = Map.parse("n next\nn last\ngg first\ng5 go 5\nx fly\n<bad> next\n")
        #expect(map.command(for: [Key("n")]) == .last)
        #expect(map.command(for: [Key("g"), Key("g")]) == .first)
        #expect(map.command(for: [Key("g"), Key("5")]) == .go(5))
        #expect(map.keys(for: .first) == [[Key("g"), Key("g")]])
        #expect(issues.map(\.line) == [5, 6])
        #expect(issues[0].description == "line 5: unknown command 'fly'")
    }

    @Test func overlayReplacesAddsAndUnbinds() {
        let base = Map.parse("n next\np first\nG last\n").keymap
        let (map, issues) = Map.overlaid("n last\nG nop\nz first\n", over: base)
        #expect(issues.isEmpty)
        #expect(map.command(for: [Key("n")]) == .last)
        #expect(map.command(for: [Key("G")]) == nil)
        #expect(map.command(for: [Key("z")]) == .first)
        #expect(map.command(for: [Key("p")]) == .first)
        #expect(Map.parse("n nop\n").keymap.bindings.isEmpty)
    }

    @Test func matcherCountsSequencesAndWaits() {
        var matcher = KeyMatcher(keymap: Map.parse("n next\ng first\ngg last\n").keymap)
        #expect(matcher.feed(Key("3")) == .pending(display: "3"))
        #expect(matcher.feed(Key("n")) == .matched(Invocation(.next, count: 3)))
        #expect(matcher.feed(Key("g")) == .pending(display: "g"))
        #expect(matcher.flush() == Invocation(.first))
        #expect(matcher.feed(Key("g")) == .pending(display: "g"))
        #expect(matcher.feed(Key("g")) == .matched(Invocation(.last)))
        #expect(matcher.feed(Key("x")) == .unmatched)
        _ = matcher.feed(Key("4"))
        #expect(matcher.feed(Key("esc")) == .pending(display: ""))
        #expect(!matcher.isPending)
        #expect(Invocation(TestCommand.next, count: 0).times == 1)
    }
}
