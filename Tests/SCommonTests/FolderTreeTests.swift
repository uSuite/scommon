import Foundation
import Testing
@testable import SCommon

struct FolderTreeTests {
    /// poc-demo/ with case folders, one of them empty.
    private func pocTree() throws -> TempFolder {
        let temp = try TempFolder()
        try temp.file("poc-demo/poc-demo-vm-start/poc-demo-vm-start-01.png")
        try temp.file("poc-demo/poc-demo-vm-start/poc-demo-vm-start-02.png")
        try temp.folder("poc-demo/poc-demo-vm-empty")
        try temp.file("poc-demo/poc-demo-vm-empty/poc-demo-vm-empty.md")
        try temp.file("poc-demo/poc-demo-vm-stop/poc-demo-vm-stop-01.png")
        try temp.file("poc-demo/poc-demo-vm-tag/poc-demo-vm-tag-01.png")
        try temp.file("poc-demo/poc-demo-vm-tag/deep/extra-01.png")
        return temp
    }

    private func name(_ url: URL?) -> String? { url?.lastPathComponent }

    @Test func nextAndPreviousSiblingsSkipEmpty() throws {
        let temp = try pocTree()
        let root = temp.url.appendingPathComponent("poc-demo")
        let start = root.appendingPathComponent("poc-demo-vm-start")
        let stop = root.appendingPathComponent("poc-demo-vm-stop")
        #expect(name(try FolderTree.sibling(of: start, offset: 1)) == "poc-demo-vm-stop")
        #expect(name(try FolderTree.sibling(of: start, offset: 2)) == "poc-demo-vm-tag")
        #expect(name(try FolderTree.sibling(of: stop, offset: -1)) == "poc-demo-vm-start")
        #expect(name(try FolderTree.sibling(of: start, offset: -1, skipEmpty: false)) == "poc-demo-vm-empty")
        #expect(try FolderTree.sibling(of: start, offset: -1) == nil)
        #expect(name(try FolderTree.sibling(of: start, offset: 9)) == "poc-demo-vm-tag")
        #expect(try FolderTree.sibling(of: root.appendingPathComponent("poc-demo-vm-tag"), offset: 1) == nil)
        #expect(try FolderTree.sibling(of: start, offset: 0) == nil)
    }

    @Test func parentStopsAtRoot() throws {
        let temp = try pocTree()
        let start = temp.url.appendingPathComponent("poc-demo/poc-demo-vm-start")
        #expect(name(FolderTree.parent(of: start)) == "poc-demo")
        #expect(FolderTree.parent(of: URL(fileURLWithPath: "/")) == nil)
    }

    @Test func firstFolderWithImagesDescends() throws {
        let temp = try pocTree()
        let root = temp.url.appendingPathComponent("poc-demo")
        #expect(name(try FolderTree.firstFolderWithImages(under: root)) == "poc-demo-vm-start")
        let empty = try temp.folder("nothing/here")
        #expect(try FolderTree.firstFolderWithImages(under: empty) == nil)
    }

    @Test func flattenedWalksDepthFirstInNaturalOrder() throws {
        let temp = try pocTree()
        let root = temp.url.appendingPathComponent("poc-demo")
        let model = try FolderModel.load(root, recursive: true)
        #expect(
            model.items.map(\.name) == [
                "poc-demo-vm-start-01.png",
                "poc-demo-vm-start-02.png",
                "poc-demo-vm-stop-01.png",
                "poc-demo-vm-tag-01.png",
                "extra-01.png",
            ]
        )
    }
}
