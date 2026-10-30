import CoreServices
import Foundation

/// File-level FSEvents for a folder tree (SV-208): files added, removed,
/// renamed or written in place anywhere under `url`, coalesced by the
/// stream's latency. Recursive, so a flattened tree is covered too.
public final class FSEventWatcher: @unchecked Sendable {
    private var stream: FSEventStreamRef?
    private let handler: @Sendable ([String]) -> Void

    public init?(
        url: URL,
        latency: TimeInterval = 0.3,
        queue: DispatchQueue = .main,
        handler: @escaping @Sendable ([String]) -> Void
    ) {
        self.handler = handler
        var context = FSEventStreamContext(
            version: 0,
            info: nil,
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        context.info = Unmanaged.passUnretained(self).toOpaque()
        let callback: FSEventStreamCallback = { _, info, count, paths, _, _ in
            guard let info else {
                return
            }
            let watcher = Unmanaged<FSEventWatcher>.fromOpaque(info).takeUnretainedValue()
            let list = unsafeBitCast(paths, to: NSArray.self) as? [String] ?? []
            watcher.handler(Array(list.prefix(count)))
        }
        let flags = UInt32(
            kFSEventStreamCreateFlagFileEvents
                | kFSEventStreamCreateFlagUseCFTypes
                | kFSEventStreamCreateFlagNoDefer
        )
        guard FileManager.default.fileExists(atPath: url.path),
            let stream = FSEventStreamCreate(
                nil,
                callback,
                &context,
                [url.path] as CFArray,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                latency,
                flags
            )
        else {
            return nil
        }
        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    deinit {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
}
