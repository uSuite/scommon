import Foundation
import Testing
@testable import SCommon

struct FolderModelTests {
    @Test func loadsSortedAndFindsIndex() throws {
        let temp = try TempFolder()
        try temp.file("shot-10.png")
        let two = try temp.file("shot-2.png")
        try temp.file("shot-1.png")
        let model = try FolderModel.load(temp.url)
        #expect(model.items.map(\.name) == ["shot-1.png", "shot-2.png", "shot-10.png"])
        #expect(model.count == 3)
        #expect(!model.isEmpty)
        #expect(model.index(of: two) == 1)
        #expect(model.index(of: temp.url.appendingPathComponent("nope.png")) == nil)
    }

    @Test func resortAndReplaceKeepOrder() throws {
        let temp = try TempFolder()
        try temp.file("a.png", bytes: 30)
        try temp.file("b.png", bytes: 10)
        var model = try FolderModel.load(temp.url)
        model.sort(by: SortOrder(key: .size))
        #expect(model.items.map(\.name) == ["b.png", "a.png"])
        try temp.file("c.png", bytes: 20)
        model.replace(items: try FolderScanner.images(in: temp.url))
        #expect(model.items.map(\.name) == ["b.png", "c.png", "a.png"])
        #expect(model.order.key == .size)
    }
}
