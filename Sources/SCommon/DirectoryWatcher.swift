import Dispatch
import Foundation

/// Calls `handler` after entries in a directory are added, removed or
/// replaced, or after any of the named `files` in it is written in place,
/// debounced so a burst of writes is one call. Atomic saves show up as
/// directory writes; in-place saves as file writes. File watches are
/// re-armed after every change because an atomic save swaps the inode.
/// No polling (SV-706).
public final class DirectoryWatcher: @unchecked Sendable {
    private let source: DispatchSourceFileSystemObject
    private let directory: URL
    private let files: [String]
    private var fileSources: [DispatchSourceFileSystemObject] = []
    private let queue: DispatchQueue
    private let debounce: DispatchTimeInterval
    private let handler: @Sendable () -> Void
    private var pending: DispatchWorkItem?

    public init?(
        url: URL,
        files: [String] = [],
        debounce: DispatchTimeInterval = .milliseconds(200),
        queue: DispatchQueue = .main,
        handler: @escaping @Sendable () -> Void
    ) {
        guard let source = Self.watch(url, queue: queue) else {
            return nil
        }
        self.source = source
        directory = url
        self.files = files
        self.queue = queue
        self.debounce = debounce
        self.handler = handler
        source.setEventHandler { [weak self] in
            self?.schedule()
        }
        source.resume()
        queue.async { [weak self] in
            self?.armFiles()
        }
    }

    deinit {
        source.cancel()
        fileSources.forEach { $0.cancel() }
    }

    private static func watch(_ url: URL, queue: DispatchQueue) -> DispatchSourceFileSystemObject? {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else {
            return nil
        }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: queue
        )
        source.setCancelHandler {
            close(descriptor)
        }
        return source
    }

    /// Watches each named file that exists now; runs on `queue`.
    private func armFiles() {
        fileSources.forEach { $0.cancel() }
        fileSources = files.compactMap { name in
            guard let file = Self.watch(directory.appendingPathComponent(name), queue: queue) else {
                return nil
            }
            file.setEventHandler { [weak self] in
                self?.schedule()
            }
            file.resume()
            return file
        }
    }

    /// Runs on `queue`, so `pending` is only touched there.
    private func schedule() {
        pending?.cancel()
        let item = DispatchWorkItem { [weak self, handler] in
            self?.armFiles()
            handler()
        }
        pending = item
        queue.asyncAfter(deadline: .now() + debounce, execute: item)
    }
}
