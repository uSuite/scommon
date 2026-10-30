import Foundation
import Testing
@testable import SCommon

/// A two-option settings type standing in for an app's config.
struct TestSettings: KeyValueSettings, Equatable {
    struct Bad: Error, CustomStringConvertible {
        let text: String
        var description: String { text }
    }

    var steps = 1
    var dark = false

    static let defaultText = "# test settings\nsteps 1\ndark false\n"

    mutating func set(_ key: String, _ value: String) throws(Bad) {
        switch key {
        case "steps":
            guard let n = Int(value) else {
                throw Bad(text: "steps: '\(value)' is not a number")
            }
            steps = n
        case "dark":
            dark = value == "true"
        default:
            throw Bad(text: "unknown option '\(key)'")
        }
    }
}

struct ConfigPathsGenericTests {
    @Test func directoryIsNamedForTheApp() {
        let home = URL(fileURLWithPath: "/Users/me")
        #expect(ConfigPaths(app: "snotate", environment: [:], home: home).directory.path == "/Users/me/.config/snotate")
        #expect(ConfigPaths(app: "scapture", environment: ["XDG_CONFIG_HOME": "/xdg"], home: home).keymap.path == "/xdg/scapture/keymap")
        #expect(ConfigPaths(app: "x", environment: ["XDG_CONFIG_HOME": "relative"], home: home).directory.path == "/Users/me/.config/x")
    }

    @Test func parseLoadAndPersistAnySettingsType() throws {
        let (parsed, issues) = TestSettings.parse("steps 4\ncolour red\nsteps many\n")
        #expect(parsed.steps == 4)
        #expect(issues == [
            LineIssue(line: 2, message: "unknown option 'colour'"),
            LineIssue(line: 3, message: "steps: 'many' is not a number"),
        ])
        let temp = try TempFolder()
        let paths = ConfigPaths(directory: temp.url.appendingPathComponent("app"))
        #expect(paths.load(TestSettings.self).config == TestSettings())
        try paths.ensureDefaults(config: TestSettings.defaultText, keymap: "")
        try paths.persist("dark", "true", as: TestSettings.self)
        #expect(try String(contentsOf: paths.config, encoding: .utf8) == "# test settings\nsteps 1\ndark true\n")
        #expect(paths.load(TestSettings.self).config.dark)
        #expect(throws: TestSettings.Bad.self) {
            try paths.persist("steps", "lots", as: TestSettings.self)
        }
        #expect(paths.load(TestSettings.self).config.steps == 1)
    }
}
