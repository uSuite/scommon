import Foundation
import Testing
@testable import SCommon

struct SorterTests {
    private func item(
        _ name: String,
        size: Int64 = 0,
        modified: TimeInterval = 0
    ) -> ImageItem {
        ImageItem(
            url: URL(fileURLWithPath: "/f/\(name)"),
            size: size,
            modified: Date(timeIntervalSince1970: modified),
            typeIdentifier: "public.image"
        )
    }

    @Test func naturalNumbers() {
        #expect(Sorter.naturalLess("case-2", "case-10"))
        #expect(Sorter.naturalLess("case-02", "case-10"))
        #expect(Sorter.naturalLess("img9.png", "img10.png"))
        #expect(!Sorter.naturalLess("case-10", "case-2"))
    }

    @Test func caseInsensitiveWithDeterministicTie() {
        #expect(Sorter.naturalLess("apple", "Banana"))
        #expect(Sorter.naturalCompare("A.png", "a.png") != .orderedSame)
        #expect(Sorter.naturalCompare("same", "same") == .orderedSame)
    }

    @Test func unicodeNames() {
        let names = ["ảnh-10.png", "ảnh-2.png", "Ảnh-1.png", "zebra.png", "éclair.png"]
        let sorted = names.sorted(by: Sorter.naturalLess)
        #expect(sorted.firstIndex(of: "ảnh-2.png")! < sorted.firstIndex(of: "ảnh-10.png")!)
        #expect(sorted.firstIndex(of: "éclair.png")! < sorted.firstIndex(of: "zebra.png")!)
    }

    @Test func byNameAscendingAndDescending() {
        let items = [item("b10"), item("b2"), item("a")]
        #expect(Sorter.sorted(items, by: SortOrder(key: .name)).map(\.name) == ["a", "b2", "b10"])
        #expect(
            Sorter.sorted(items, by: SortOrder(key: .name, descending: true)).map(\.name)
                == ["b10", "b2", "a"]
        )
    }

    @Test func byDateThenName() {
        let items = [item("c", modified: 5), item("b", modified: 1), item("a", modified: 5)]
        #expect(Sorter.sorted(items, by: SortOrder(key: .date)).map(\.name) == ["b", "a", "c"])
    }

    @Test func bySize() {
        let items = [item("big", size: 100), item("small", size: 1), item("mid", size: 50)]
        #expect(Sorter.sorted(items, by: SortOrder(key: .size)).map(\.name) == ["small", "mid", "big"])
    }

    @Test func byTypeThenName() {
        let items = [item("b.png"), item("a.PNG"), item("c.gif"), item("d.jpg")]
        #expect(
            Sorter.sorted(items, by: SortOrder(key: .type)).map(\.name)
                == ["c.gif", "d.jpg", "a.PNG", "b.png"]
        )
    }
}
