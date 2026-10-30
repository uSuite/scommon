import Foundation

/// PoC evidence naming (SV-601): case folders `poc-<product>-<area>-<action>`
/// holding captures `<case-id>-<nn>.png` or `<tool>-YYYY-MM-DD-HHMMSS.png`,
/// where `<tool>` is any lower-case prefix (`scap-` from sCapture).
public struct PocCase: Sendable, Equatable {
    public let caseID: String
    public let product: String
    public let area: String
    public let action: String

    public enum Step: Sendable, Equatable, CustomStringConvertible {
        case number(Int)
        case timestamp(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int)

        public var description: String {
            switch self {
            case .number(let n):
                return "step \(n)"
            case .timestamp(let year, let month, let day, let hour, let minute, let second):
                return String(format: "%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second)
            }
        }
    }

    /// A case folder name, or `nil` for a product folder (`poc-demo`) or
    /// anything that does not match `^poc-[a-z0-9-]+$`.
    public init?(folderName: String) {
        guard folderName.wholeMatch(of: /poc-[a-z0-9]+(-[a-z0-9]+)*/) != nil else {
            return nil
        }
        let parts = folderName.split(separator: "-").dropFirst().map(String.init)
        guard parts.count >= 3 else {
            return nil
        }
        caseID = folderName
        product = parts[0]
        area = parts[1]
        action = parts.dropFirst(2).joined(separator: "-")
    }

    /// The product name when `folderName` is a product folder like `poc-demo`.
    public static func product(folderName: String) -> String? {
        guard let match = folderName.wholeMatch(of: /poc-([a-z0-9]+)/) else {
            return nil
        }
        return String(match.1)
    }

    /// The step of a capture in this case folder, if its name follows either pattern.
    public func step(fileName: String) -> Step? {
        let stem = (fileName as NSString).deletingPathExtension
        if stem.hasPrefix(caseID + "-"), let n = Int(stem.dropFirst(caseID.count + 1)), n >= 0 {
            return .number(n)
        }
        return Self.timestamp(stem)
    }

    static func timestamp(_ stem: String) -> Step? {
        guard let match = stem.wholeMatch(of: /[a-z]+-(\d{4})-(\d{2})-(\d{2})-(\d{2})(\d{2})(\d{2})/),
            let year = Int(match.1),
            let month = Int(match.2),
            let day = Int(match.3),
            let hour = Int(match.4),
            let minute = Int(match.5),
            let second = Int(match.6),
            (1...12).contains(month),
            (1...31).contains(day),
            hour < 24,
            minute < 60,
            second < 61
        else {
            return nil
        }
        return .timestamp(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    }

    /// Title fragment for the window: `poc-demo-vm-stop  step 3`.
    public func title(fileName: String) -> String {
        guard let step = step(fileName: fileName) else {
            return caseID
        }
        return "\(caseID)  \(step)"
    }
}
