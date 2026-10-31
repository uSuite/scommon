import Foundation
import Testing
@testable import SCommon

struct SandboxTests {
    @Test func theContainerIdMeansSandboxed() {
        #expect(Sandbox.isActive(environment: ["APP_SANDBOX_CONTAINER_ID": "io.github.usuite.sview"]))
        #expect(!Sandbox.isActive(environment: ["HOME": "/tmp/home"]))
    }

    @Test func testsRunOutsideTheSandbox() {
        #expect(!Sandbox.isActive)
    }
}
