import Foundation

public enum SortKey: String, Sendable, CaseIterable {
    case name
    case date
    case size
    case type
}

public struct SortOrder: Sendable, Hashable {
    public var key: SortKey
    public var descending: Bool

    public init(
        key: SortKey = .name,
        descending: Bool = false
    ) {
        self.key = key
        self.descending = descending
    }
}

/// Orders images (SV-202). Name order is natural, so `case-2` precedes
/// `case-10`, and groups by folder first for a flattened tree; ties on date, size or type fall back to name order so the
/// sequence is always deterministic.
public enum Sorter {
    public static func naturalCompare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let result = lhs.localizedStandardCompare(rhs)
        if result != .orderedSame {
            return result
        }
        return lhs.compare(rhs, options: .literal)
    }

    public static func naturalLess(_ lhs: String, _ rhs: String) -> Bool {
        naturalCompare(lhs, rhs) == .orderedAscending
    }

    public static func sorted(_ items: [ImageItem], by order: SortOrder) -> [ImageItem] {
        let ascending = items.sorted { lhs, rhs in
            switch compare(lhs, rhs, key: order.key) {
            case .orderedAscending:
                return true
            case .orderedDescending:
                return false
            case .orderedSame:
                return naturalLess(lhs.name, rhs.name)
            }
        }
        return order.descending ? ascending.reversed() : ascending
    }

    private static func compare(_ lhs: ImageItem, _ rhs: ImageItem, key: SortKey) -> ComparisonResult {
        switch key {
        case .name:
            let byFolder = naturalCompare(
                lhs.url.deletingLastPathComponent().path,
                rhs.url.deletingLastPathComponent().path
            )
            return byFolder == .orderedSame ? naturalCompare(lhs.name, rhs.name) : byFolder
        case .date:
            return order(lhs.modified, rhs.modified)
        case .size:
            return order(lhs.size, rhs.size)
        case .type:
            return naturalCompare(
                lhs.url.pathExtension.lowercased(),
                rhs.url.pathExtension.lowercased()
            )
        }
    }

    private static func order<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        lhs < rhs ? .orderedAscending : (lhs > rhs ? .orderedDescending : .orderedSame)
    }
}
