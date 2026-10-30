import Testing
@testable import SCommon

struct KeyTests {
    @Test func characterSequences() throws {
        #expect(try Key.parseSequence("gg") == [Key("g"), Key("g")])
        #expect(try Key.parseSequence("G") == [Key("G")])
        #expect(try Key.parseSequence("]") == [Key("]")])
        #expect(try Key.parseSequence("g<space>") == [Key("g"), Key("space")])
        #expect(try Key.parseSequence("<ctrl-d>x") == [Key("d", modifiers: .control), Key("x")])
    }

    @Test func wholeTokenNamedKeys() throws {
        #expect(try Key.parseSequence("space") == [Key(" ")])
        #expect(try Key.parseSequence("shift-space") == [Key(" ", modifiers: .shift)])
        #expect(try Key.parseSequence("cmd-n") == [Key("n", modifiers: .command)])
        #expect(try Key.parseSequence("ctrl-shift-left") == [Key("left", modifiers: [.control, .shift])])
        #expect(try Key.parseSequence("Esc") == [Key("esc")])
        #expect(try Key.parseSequence("lt") == [Key("<")])
        #expect(try Key.parseSequence("hash") == [Key("#")])
    }

    @Test func shiftIsDroppedForCharacters() {
        #expect(Key("G", modifiers: .shift) == Key("G"))
        #expect(Key("left", modifiers: .shift) != Key("left"))
    }

    @Test func errors() {
        #expect(throws: Key.ParseError.empty) { try Key.parseSequence("") }
        #expect(throws: Key.ParseError.badKey("bogus")) { try Key.parseSequence("<bogus>") }
        #expect(throws: Key.ParseError.badKey("cmd-zz")) { try Key.parseNamed("cmd-zz") }
        #expect(Key.ParseError.empty.description == "no keys")
    }

    @Test func descriptions() {
        #expect(Key("g").description == "g")
        #expect(Key(" ").description == "<space>")
        #expect(Key(" ", modifiers: .shift).description == "<shift-space>")
        #expect(Key("n", modifiers: [.command, .control]).description == "<cmd-ctrl-n>")
        #expect(Key("#").description == "<hash>")
        #expect(Key("left").description == "<left>")
        #expect(Key("5").isDigit)
        #expect(!Key("5", modifiers: .control).isDigit)
        #expect(!Key("x").isDigit)
    }
}
