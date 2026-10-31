import Foundation

/// An s-app's settings as a zip (DECISIONS 2026-10-30): export writes its
/// `fileNames` that exist, never state.json, into one `<app>/` folder, so
/// unzipping it in `~/.config` puts the files back; import reads such a zip
/// (or one with the files at its root) and lets the app check each file
/// before anything changes, then keeps every replaced file as
/// `<name>.bak`. From sView's and sNotate's `ConfigExport` and sNotate's
/// `ConfigImport`. `ditto` only ever touches the temporary folder, which is
/// in the container in a sandboxed app; the app itself copies the zip to
/// and from the place the user chose (DECISIONS 2026-10-31).
public struct ConfigArchive: Sendable, Equatable {
    /// The folder name in the zip and the start of the default file name.
    public let app: String
    /// The files that travel, in this order.
    public let fileNames: [String]

    public init(
        app: String,
        fileNames: [String]
    ) {
        self.app = app
        self.fileNames = fileNames
    }

    public enum Failure: Error, Equatable, CustomStringConvertible {
        /// The files the archive looks for, listed as `config or keymap`.
        case nothingToExport(String)
        case zipFailed(String)
        case unzipFailed(String)
        case nothingToImport(String)
        case notText(String)
        case writeFailed(String)

        public var description: String {
            switch self {
            case .nothingToExport(let files):
                return "no \(files) to export"
            case .zipFailed(let reason):
                return "export failed: \(reason)"
            case .unzipFailed(let reason):
                return "the zip cannot be opened: \(reason)"
            case .nothingToImport(let files):
                return "the zip holds no \(files)"
            case .notText(let name):
                return "\(name) in the zip is not UTF-8 text"
            case .writeFailed(let reason):
                return "import failed: \(reason)"
            }
        }
    }

    /// One file a zip brings, with the problems the app found in it.
    public struct File: Sendable, Equatable {
        public let name: String
        public let data: Data
        public let issues: [String]

        public init(
            name: String,
            data: Data,
            issues: [String]
        ) {
            self.name = name
            self.data = data
            self.issues = issues
        }
    }

    /// `config, keymap or styles`, for messages.
    public var listed: String {
        guard fileNames.count > 1 else {
            return fileNames.first ?? ""
        }
        return fileNames.dropLast().joined(separator: ", ") + " or " + fileNames.last!
    }

    /// Where the archive goes. An empty `path` means the Desktop; a path the
    /// user names is theirs, so an existing file there is replaced, as cp
    /// would; a path is `~`-expanded, taken relative to `folder` when
    /// relative, gets `.zip` when it has no extension, and names a folder
    /// when it is one. The default name carries the date and never
    /// overwrites a file.
    public func destination(
        for path: String,
        folder: URL?,
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        date: Date = Date()
    ) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let name = "\(app)-config-\(formatter.string(from: date))"
        guard !path.trimmingCharacters(in: .whitespaces).isEmpty else {
            return Self.unused(home.appendingPathComponent("Desktop").appendingPathComponent(name + ".zip"))
        }
        var expanded = path.trimmingCharacters(in: .whitespaces)
        if expanded == "~" || expanded.hasPrefix("~/") {
            expanded = home.path + expanded.dropFirst()
        }
        let base = folder ?? home
        var url = expanded.hasPrefix("/")
            ? URL(fileURLWithPath: expanded)
            : base.appendingPathComponent(expanded)
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return Self.unused(url.appendingPathComponent(name + ".zip"))
        }
        if url.pathExtension.isEmpty {
            url.appendPathExtension("zip")
        }
        return url.standardizedFileURL
    }

    /// `url`, or `url` with -2, -3 ... before the extension when taken.
    static func unused(_ url: URL) -> URL {
        var candidate = url
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let stem = url.deletingPathExtension().lastPathComponent
            candidate = url.deletingLastPathComponent().appendingPathComponent("\(stem)-\(n).\(url.pathExtension)")
            n += 1
        }
        return candidate
    }

    /// Writes the archive and returns the names it holds, `<app>/<file>`.
    @concurrent
    public func export(
        from paths: ConfigPaths,
        to destination: URL
    ) async throws(Failure) -> [String] {
        let present = fileNames.filter {
            FileManager.default.fileExists(atPath: paths.directory.appendingPathComponent($0).path)
        }
        guard !present.isEmpty else {
            throw .nothingToExport(listed)
        }
        let staging = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(app)-export-\(UUID().uuidString)")
        let folder = staging.appendingPathComponent(app)
        defer { try? FileManager.default.removeItem(at: staging) }
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for name in present {
                try FileManager.default.copyItem(
                    at: paths.directory.appendingPathComponent(name),
                    to: folder.appendingPathComponent(name)
                )
            }
        } catch {
            throw .zipFailed(error.localizedDescription)
        }
        // No resource forks, extended attributes or quarantine: those become
        // ._ files in a zip, which other machines would unpack as clutter.
        let zip = staging.appendingPathComponent("\(app).zip")
        if let failure = Self.ditto([
            "-c", "-k", "--norsrc", "--noextattr", "--noqtn", "--keepParent",
            folder.path, zip.path,
        ]) {
            throw .zipFailed(failure)
        }
        do {
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: zip, to: destination)
        } catch {
            throw .zipFailed(error.localizedDescription)
        }
        return present.map { "\(app)/\($0)" }
    }

    /// The files a zip brings, in `fileNames` order, each with the problems
    /// `check(name, text)` finds; nothing is written.
    @concurrent
    public func inspect(
        _ zip: URL,
        check: @Sendable (_ name: String, _ text: String) -> [String]
    ) async throws(Failure) -> [File] {
        let staging = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(app)-import-\(UUID().uuidString)")
        let unpacked = staging.appendingPathComponent("unpacked")
        let copy = staging.appendingPathComponent("in.zip")
        defer { try? FileManager.default.removeItem(at: staging) }
        do {
            try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: zip, to: copy)
        } catch {
            throw .unzipFailed(error.localizedDescription)
        }
        if let failure = Self.ditto(["-x", "-k", copy.path, unpacked.path]) {
            throw .unzipFailed(failure)
        }
        let nested = unpacked.appendingPathComponent(app)
        var isDirectory: ObjCBool = false
        let folder = FileManager.default.fileExists(atPath: nested.path, isDirectory: &isDirectory) && isDirectory.boolValue
            ? nested
            : unpacked
        var files: [File] = []
        for name in fileNames {
            guard let data = FileManager.default.contents(atPath: folder.appendingPathComponent(name).path) else {
                continue
            }
            guard let text = String(data: data, encoding: .utf8) else {
                throw .notText(name)
            }
            files.append(
                File(
                    name: name,
                    data: data,
                    issues: check(name, text)
                )
            )
        }
        guard !files.isEmpty else {
            throw .nothingToImport(listed)
        }
        return files
    }

    /// Writes `files` into `directory`, each replaced file kept as
    /// `<name>.bak` (an older backup is replaced), and returns their names.
    public static func apply(
        _ files: [File],
        to directory: URL
    ) throws(Failure) -> [String] {
        let manager = FileManager.default
        do {
            try manager.createDirectory(at: directory, withIntermediateDirectories: true)
            for file in files {
                let target = directory.appendingPathComponent(file.name)
                if manager.fileExists(atPath: target.path) {
                    let backup = directory.appendingPathComponent(file.name + ".bak")
                    if manager.fileExists(atPath: backup.path) {
                        try manager.removeItem(at: backup)
                    }
                    try manager.copyItem(at: target, to: backup)
                }
                try file.data.write(to: target, options: .atomic)
            }
        } catch {
            throw .writeFailed(error.localizedDescription)
        }
        return files.map(\.name)
    }

    /// Runs `/usr/bin/ditto`; `nil` when it worked, what it said otherwise.
    static func ditto(_ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = arguments
        let errors = Pipe()
        process.standardError = errors
        do {
            try process.run()
        } catch {
            return error.localizedDescription
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            return message.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
}
