import Foundation

/// Whether this process runs in the App Sandbox (DECISIONS 2026-10-31):
/// true in every shipped build, false for a plain `swift run` or a test.
/// The one runtime fact the apps branch on; no compile flag says it.
public enum Sandbox {
    public static var isActive: Bool {
        isActive(environment: ProcessInfo.processInfo.environment)
    }

    static func isActive(environment: [String: String]) -> Bool {
        environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }
}
