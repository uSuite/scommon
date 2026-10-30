import Foundation
import Testing
@testable import SCommon

struct FSEventWatcherTests {
    final class Paths: @unchecked Sendable {
        private let lock = NSLock()
        private var seen: [String] = []

        func add(_ paths: [String]) {
            lock.withLock { seen += paths }
        }

        var all: [String] { lock.withLock { seen } }
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<150 where !condition() {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    @Test func seesNewFilesAndInPlaceWrites() async throws {
        let temp = try TempFolder()
        let file = try temp.file("a.png")
        let paths = Paths()
        let watcher = FSEventWatcher(url: temp.url, latency: 0.05, queue: DispatchQueue(label: "fsevents-test")) {
            paths.add($0)
        }
        #expect(watcher != nil)
        try? await Task.sleep(for: .milliseconds(200))
        try temp.file("sub/new.png")
        await waitUntil { paths.all.contains { $0.hasSuffix("sub/new.png") } }
        #expect(paths.all.contains { $0.hasSuffix("sub/new.png") })
        let handle = try FileHandle(forWritingTo: file)
        try handle.write(contentsOf: Data("x".utf8))
        try handle.close()
        await waitUntil { paths.all.contains { $0.hasSuffix("/a.png") } }
        #expect(paths.all.contains { $0.hasSuffix("/a.png") })
        _ = watcher
    }

    @Test func missingFolderIsNil() {
        #expect(FSEventWatcher(url: URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString)")) { _ in } == nil)
    }
}
