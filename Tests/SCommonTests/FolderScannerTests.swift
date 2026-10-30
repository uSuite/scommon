import Foundation
import Testing
@testable import SCommon

struct FolderScannerTests {
    @Test func listsOnlyVisibleImages() throws {
        let temp = try TempFolder()
        try temp.file("a.png")
        try temp.file("b.JPG")
        try temp.file("c.heic")
        try temp.file("notes.md")
        try temp.file("script.sh")
        try temp.file(".hidden.png")
        try temp.file("._a.png")
        try temp.folder("sub.png")
        let names = try FolderScanner.images(in: temp.url).map(\.name).sorted()
        #expect(names == ["a.png", "b.JPG", "c.heic"])
    }

    @Test func recordsSizeAndType() throws {
        let temp = try TempFolder()
        try temp.file("x.png", bytes: 42)
        let item = try #require(try FolderScanner.images(in: temp.url).first)
        #expect(item.size == 42)
        #expect(item.typeIdentifier == "public.png")
        #expect(item.stem == "x")
    }

    @Test func subfoldersAreNaturalSortedAndVisible() throws {
        let temp = try TempFolder()
        try temp.folder("case-10")
        try temp.folder("case-2")
        try temp.folder(".git")
        try temp.folder("case-1")
        try temp.file("case-3")
        let names = try FolderScanner.subfolders(of: temp.url).map(\.lastPathComponent)
        #expect(names == ["case-1", "case-2", "case-10"])
    }

    @Test func keepsTheCallersPathForm() throws {
        let temp = try TempFolder()
        try temp.file("a.png")
        try temp.folder("sub")
        #expect(try FolderScanner.images(in: temp.url).first?.url.path == temp.url.path + "/a.png")
        #expect(try FolderScanner.subfolders(of: temp.url).first?.path == temp.url.path + "/sub")
    }

    @Test func missingFolderThrows() {
        let missing = URL(fileURLWithPath: "/nonexistent/sview/\(UUID().uuidString)")
        #expect(throws: (any Error).self) {
            try FolderScanner.images(in: missing)
        }
    }

    @Test func isImageUsesTypeConformance() throws {
        let temp = try TempFolder()
        #expect(FolderScanner.isImage(try temp.file("a.webp")))
        #expect(!FolderScanner.isImage(try temp.file("a.txt")))
        #expect(FolderScanner.isImage(URL(fileURLWithPath: "/nowhere/x.tiff")))
        #expect(FolderScanner.isHidden(URL(fileURLWithPath: "/x/._y.png")))
    }
}
