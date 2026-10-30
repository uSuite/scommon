import Foundation
import Testing
@testable import SCommon

struct DirectoryWatcherTests {
    final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0

        func increment() {
            lock.withLock { value += 1 }
        }

        var count: Int { lock.withLock { value } }
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<100 where !condition() {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    @Test func burstOfWritesIsOneCall() async throws {
        let temp = try TempFolder()
        let counter = Counter()
        let queue = DispatchQueue(label: "watcher-test")
        let watcher = DirectoryWatcher(url: temp.url, debounce: .milliseconds(100), queue: queue) {
            counter.increment()
        }
        #expect(watcher != nil)
        for n in 1...5 {
            try Data("\(n)".utf8).write(to: temp.url.appendingPathComponent("config"), options: .atomic)
        }
        await waitUntil { counter.count > 0 }
        try? await Task.sleep(for: .milliseconds(300))
        #expect(counter.count == 1)
        try temp.file("new.png")
        await waitUntil { counter.count > 1 }
        #expect(counter.count == 2)
        _ = watcher
    }

    @Test func inPlaceWritesToNamedFilesAreSeen() async throws {
        let temp = try TempFolder()
        let file = try temp.file("keymap")
        let counter = Counter()
        let queue = DispatchQueue(label: "watcher-files")
        let watcher = DirectoryWatcher(url: temp.url, files: ["keymap"], debounce: .milliseconds(50), queue: queue) {
            counter.increment()
        }
        try? await Task.sleep(for: .milliseconds(100))
        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("zz first\n".utf8))
        try handle.close()
        await waitUntil { counter.count > 0 }
        #expect(counter.count == 1)
        // After an atomic replace the new file is watched too.
        try Data("a\n".utf8).write(to: file, options: .atomic)
        await waitUntil { counter.count > 1 }
        try? await Task.sleep(for: .milliseconds(150))
        let appender = try FileHandle(forWritingTo: file)
        try appender.seekToEnd()
        try appender.write(contentsOf: Data("b\n".utf8))
        try appender.close()
        await waitUntil { counter.count > 2 }
        #expect(counter.count == 3)
        _ = watcher
    }

    @Test func missingDirectoryIsNil() {
        let missing = URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString)")
        #expect(DirectoryWatcher(url: missing) { } == nil)
    }
}
