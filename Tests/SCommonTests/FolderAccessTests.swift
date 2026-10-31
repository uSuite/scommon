import Foundation
import Testing
@testable import SCommon

@MainActor
struct FolderAccessTests {
    private func access(_ temp: TempFolder) -> FolderAccess {
        FolderAccess(
            bookmarks: Bookmarks(
                file: temp.url.appendingPathComponent("config/bookmarks"),
                securityScoped: false
            )
        )
    }

    @Test func aListableFolderIsNeverAskedFor() async throws {
        let temp = try TempFolder()
        let folder = try temp.folder("case")
        var asked = 0
        let result = await access(temp).ensureReadable(folder) { _ in
            asked += 1
            return nil
        }
        #expect(result == folder)
        #expect(asked == 0)
        #expect(access(temp).bookmarks.folders.isEmpty)
    }

    @Test func anUnreadableFolderIsAskedForOnceAndTheAnswerKept() async throws {
        let temp = try TempFolder()
        let folder = try temp.folder("locked")
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: folder.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder.path) }
        var asked: [URL] = []
        let result = await access(temp).ensureReadable(folder) { url in
            asked.append(url)
            return url
        }
        #expect(asked == [folder])
        // Outside the sandbox a bookmark cannot lift POSIX permissions, so
        // the folder stays unlistable; what matters is that it was kept.
        #expect(result == nil)
        #expect(access(temp).bookmarks.folders == [Bookmarks.key(folder)])
    }

    @Test func decliningRemembersNothing() async throws {
        let temp = try TempFolder()
        let folder = try temp.folder("locked")
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: folder.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder.path) }
        let result = await access(temp).ensureReadable(folder) { _ in nil }
        #expect(result == nil)
        #expect(access(temp).bookmarks.folders.isEmpty)
    }
}
