import Foundation
import Testing
@testable import SCommon

struct ConfigArchiveTests {
    private let archive = ConfigArchive(
        app: "demo",
        fileNames: ["config", "keymap", "styles"]
    )
    private let date = Date(timeIntervalSince1970: 1_793_000_000)

    private func paths(_ temp: TempFolder) throws -> ConfigPaths {
        let paths = ConfigPaths(directory: temp.url.appendingPathComponent("demo"))
        try paths.ensureDefaults(config: "snap true\n", keymap: "n next\n")
        return paths
    }

    private func zip(
        _ temp: TempFolder,
        _ files: [String: String],
        nested: Bool
    ) throws -> URL {
        let source = temp.url.appendingPathComponent("source-\(UUID().uuidString)")
        let folder = nested ? source.appendingPathComponent("demo") : source
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (name, text) in files {
            try Data(text.utf8).write(to: folder.appendingPathComponent(name))
        }
        let zip = temp.url.appendingPathComponent("in-\(UUID().uuidString).zip")
        let arguments = nested
            ? ["-c", "-k", "--keepParent", folder.path, zip.path]
            : ["-c", "-k", folder.path, zip.path]
        #expect(ConfigArchive.ditto(arguments) == nil)
        return zip
    }

    @Test func theDefaultIsADatedZipOnTheDesktopThatNeverOverwrites() throws {
        let temp = try TempFolder()
        try FileManager.default.createDirectory(at: temp.url.appendingPathComponent("Desktop"), withIntermediateDirectories: true)
        let first = archive.destination(for: "", folder: nil, home: temp.url, date: date)
        #expect(first.deletingLastPathComponent().lastPathComponent == "Desktop")
        #expect(first.lastPathComponent.hasPrefix("demo-config-20"))
        #expect(first.pathExtension == "zip")
        try Data().write(to: first)
        let second = archive.destination(for: "", folder: nil, home: temp.url, date: date)
        #expect(second.lastPathComponent == first.deletingPathExtension().lastPathComponent + "-2.zip")
    }

    @Test func pathsExpandResolveAndGetTheZipExtension() throws {
        let temp = try TempFolder()
        let folder = temp.url.appendingPathComponent("shots")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        #expect(archive.destination(for: "~/backup", folder: nil, home: temp.url).path == temp.url.path + "/backup.zip")
        #expect(archive.destination(for: "/tmp/x.zip", folder: folder, home: temp.url).path == "/tmp/x.zip")
        #expect(archive.destination(for: "mine.zip", folder: folder, home: temp.url).path == folder.path + "/mine.zip")
        let inFolder = archive.destination(for: "~/shots", folder: nil, home: temp.url, date: date)
        #expect(inFolder.deletingLastPathComponent().path == folder.path)
        #expect(inFolder.lastPathComponent.hasPrefix("demo-config-"))
    }

    @Test func exportHoldsTheAppsFolderWithTheFilesThatExistButNotState() async throws {
        let temp = try TempFolder()
        let paths = try paths(temp)
        try Data("{}".utf8).write(to: paths.state)
        // An extended attribute must not become a ._keymap entry.
        let value = Array("tag".utf8)
        #expect(setxattr(paths.keymap.path, "com.example.note", value, value.count, 0, 0) == 0)
        let zip = temp.url.appendingPathComponent("out/settings.zip")
        let names = try await archive.export(from: paths, to: zip)
        #expect(names == ["demo/config", "demo/keymap"])
        let list = Process()
        list.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        list.arguments = ["-Z1", zip.path]
        let pipe = Pipe()
        list.standardOutput = pipe
        try list.run()
        list.waitUntilExit()
        let entries = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            .split(separator: "\n").map(String.init).sorted()
        #expect(entries == ["demo/", "demo/config", "demo/keymap"])
    }

    @Test func nothingToExportIsAnError() async throws {
        let temp = try TempFolder()
        let paths = ConfigPaths(directory: temp.url.appendingPathComponent("empty"))
        await #expect(throws: ConfigArchive.Failure.nothingToExport("config, keymap or styles")) {
            try await archive.export(from: paths, to: temp.url.appendingPathComponent("x.zip"))
        }
        #expect(ConfigArchive.Failure.nothingToExport("config, keymap or styles").description == "no config, keymap or styles to export")
        #expect(ConfigArchive(app: "two", fileNames: ["config", "keymap"]).listed == "config or keymap")
    }

    @Test func anExportedZipComesBackAndTheReplacedFilesAreKept() async throws {
        let temp = try TempFolder()
        let paths = try paths(temp)
        try Data("preset 4\n".utf8).write(to: paths.directory.appendingPathComponent("styles"))
        let zip = temp.url.appendingPathComponent("out.zip")
        _ = try await archive.export(from: paths, to: zip)

        try Data("snap false\n".utf8).write(to: paths.config)
        try Data("{}".utf8).write(to: paths.state)
        let files = try await archive.inspect(zip) { name, _ in
            name == "keymap" ? ["line 1: checked"] : []
        }
        #expect(files.map(\.name) == ["config", "keymap", "styles"])
        #expect(files.map(\.issues) == [[], ["line 1: checked"], []])
        let written = try ConfigArchive.apply(files, to: paths.directory)
        #expect(written == ["config", "keymap", "styles"])
        #expect(try String(contentsOf: paths.config, encoding: .utf8) == "snap true\n")
        #expect(try String(contentsOf: paths.directory.appendingPathComponent("config.bak"), encoding: .utf8) == "snap false\n")
        #expect(try String(contentsOf: paths.state, encoding: .utf8) == "{}")
    }

    @Test func filesAtTheZipsRootAreTakenAndOthersIgnored() async throws {
        let temp = try TempFolder()
        let zip = try zip(temp, ["keymap": "j next\n", "notes.txt": "x"], nested: false)
        let files = try await archive.inspect(zip) { _, _ in [] }
        #expect(files.map(\.name) == ["keymap"])
        #expect(String(decoding: files[0].data, as: UTF8.self) == "j next\n")
    }

    @Test func aZipWithoutOurFilesOrNotAZipIsRefused() async throws {
        let temp = try TempFolder()
        let zip = try zip(temp, ["readme": "hello"], nested: true)
        await #expect(throws: ConfigArchive.Failure.nothingToImport("config, keymap or styles")) {
            try await archive.inspect(zip) { _, _ in [] }
        }
        let plain = temp.url.appendingPathComponent("plain.zip")
        try Data("not a zip".utf8).write(to: plain)
        await #expect(throws: ConfigArchive.Failure.self) {
            try await archive.inspect(plain) { _, _ in [] }
        }
    }

    @Test func aFileThatIsNotTextIsRefused() async throws {
        let temp = try TempFolder()
        let source = temp.url.appendingPathComponent("bin/demo")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try Data([0xFF, 0xFE, 0x00]).write(to: source.appendingPathComponent("config"))
        let zip = temp.url.appendingPathComponent("bin.zip")
        #expect(ConfigArchive.ditto(["-c", "-k", "--keepParent", source.path, zip.path]) == nil)
        await #expect(throws: ConfigArchive.Failure.notText("config")) {
            try await archive.inspect(zip) { _, _ in [] }
        }
    }

    @Test func anOlderBackupIsReplaced() throws {
        let temp = try TempFolder()
        let directory = temp.url.appendingPathComponent("demo")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("old\n".utf8).write(to: directory.appendingPathComponent("keymap.bak"))
        try Data("current\n".utf8).write(to: directory.appendingPathComponent("keymap"))
        _ = try ConfigArchive.apply([ConfigArchive.File(name: "keymap", data: Data("new\n".utf8), issues: [])], to: directory)
        #expect(try String(contentsOf: directory.appendingPathComponent("keymap.bak"), encoding: .utf8) == "current\n")
        #expect(try String(contentsOf: directory.appendingPathComponent("keymap"), encoding: .utf8) == "new\n")
    }
}
