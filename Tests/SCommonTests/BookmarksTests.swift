import Foundation
import Testing
@testable import SCommon

struct BookmarksTests {
    private func store(_ temp: TempFolder) -> Bookmarks {
        Bookmarks(
            file: temp.url.appendingPathComponent("config/bookmarks"),
            securityScoped: false
        )
    }

    @Test func aRememberedFolderCoversItselfAndWhatIsInIt() throws {
        let temp = try TempFolder()
        let cases = try temp.folder("poc/cases")
        let step = try temp.folder("poc/cases/poc-demo/sub")
        let bookmarks = store(temp)
        try bookmarks.remember(cases)
        #expect(bookmarks.folder(covering: cases).map(Bookmarks.key) == Bookmarks.key(cases))
        #expect(bookmarks.folder(covering: step).map(Bookmarks.key) == Bookmarks.key(cases))
        #expect(bookmarks.folder(covering: try temp.folder("poc")) == nil)
        #expect(bookmarks.folder(covering: try temp.folder("poc/cases-old")) == nil)
    }

    @Test func theDeepestRememberedFolderWins() throws {
        let temp = try TempFolder()
        let root = try temp.folder("root")
        let inner = try temp.folder("root/inner")
        let bookmarks = store(temp)
        try bookmarks.remember(root)
        try bookmarks.remember(inner)
        let found = bookmarks.folder(covering: try temp.folder("root/inner/deeper"))
        #expect(found.map(Bookmarks.key) == Bookmarks.key(inner))
    }

    @Test func rememberingTwiceKeepsOneLineAndForgetDropsIt() throws {
        let temp = try TempFolder()
        let folder = try temp.folder("a")
        let bookmarks = store(temp)
        try bookmarks.remember(folder)
        try bookmarks.remember(folder)
        #expect(bookmarks.folders == [Bookmarks.key(folder)])
        try bookmarks.forget(folder)
        #expect(bookmarks.folders.isEmpty)
    }

    @Test func theFileSurvivesANewStoreAndIsOneLinePerFolder() throws {
        let temp = try TempFolder()
        let a = try temp.folder("a")
        let b = try temp.folder("b")
        try store(temp).remember(a)
        try store(temp).remember(b)
        #expect(store(temp).folders == [Bookmarks.key(a), Bookmarks.key(b)])
        let text = try String(contentsOf: store(temp).file, encoding: .utf8)
        #expect(text.split(separator: "\n").count == 2)
        #expect(text.split(separator: "\n").allSatisfy { $0.split(separator: "\t").count == 2 })
    }

    @Test func aFolderThatIsGoneIsDropped() throws {
        let temp = try TempFolder()
        let folder = try temp.folder("gone")
        let bookmarks = store(temp)
        try bookmarks.remember(folder)
        try FileManager.default.removeItem(at: folder)
        #expect(bookmarks.folder(covering: folder) == nil)
        #expect(bookmarks.folders.isEmpty)
    }

    @Test func aBrokenLineIsSkipped() throws {
        let temp = try TempFolder()
        let folder = try temp.folder("ok")
        let bookmarks = store(temp)
        try bookmarks.remember(folder)
        let text = try String(contentsOf: bookmarks.file, encoding: .utf8)
        try Data(("no tab here\n/x\tnot base64!\n" + text).utf8).write(to: bookmarks.file)
        #expect(bookmarks.folders == [Bookmarks.key(folder)])
        #expect(bookmarks.folder(covering: folder) != nil)
    }

    @Test func withAccessRunsTheBodyOnlyWhenAFolderCovers() throws {
        let temp = try TempFolder()
        let folder = try temp.folder("granted")
        let bookmarks = store(temp)
        #expect(bookmarks.withAccess(to: folder) { _ in 1 } == nil)
        try bookmarks.remember(folder)
        #expect(bookmarks.withAccess(to: folder) { _ in 1 } == 1)
    }

    @Test func theFileLivesBesideTheConfig() {
        let paths = ConfigPaths(directory: URL(fileURLWithPath: "/tmp/demo"))
        #expect(Bookmarks(paths: paths, securityScoped: false).file.path == "/tmp/demo/bookmarks")
    }
}
