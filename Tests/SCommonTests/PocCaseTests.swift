import Testing
@testable import SCommon

struct PocCaseTests {
    @Test func parsesCaseFolders() throws {
        let poc = try #require(PocCase(folderName: "poc-demo-vm-stop"))
        #expect(poc.caseID == "poc-demo-vm-stop")
        #expect(poc.product == "demo")
        #expect(poc.area == "vm")
        #expect(poc.action == "stop")
        let long = try #require(PocCase(folderName: "poc-demo-ui-dashboard-load-test"))
        #expect(long.action == "dashboard-load-test")
    }

    @Test func rejectsNonCases() {
        #expect(PocCase(folderName: "poc-demo") == nil)
        #expect(PocCase(folderName: "poc-demo-vm") == nil)
        #expect(PocCase(folderName: "POC-demo-vm-stop") == nil)
        #expect(PocCase(folderName: "poc-demo--stop") == nil)
        #expect(PocCase(folderName: "poc-de mo-vm-stop") == nil)
        #expect(PocCase(folderName: "photos") == nil)
        #expect(PocCase.product(folderName: "poc-demo") == "demo")
        #expect(PocCase.product(folderName: "poc-demo-vm-stop") == nil)
    }

    @Test func stepFromNumberedCapture() throws {
        let poc = try #require(PocCase(folderName: "poc-demo-vm-stop"))
        #expect(poc.step(fileName: "poc-demo-vm-stop-03.png") == .number(3))
        #expect(poc.step(fileName: "poc-demo-vm-stop-12.PNG") == .number(12))
        #expect(poc.step(fileName: "poc-demo-vm-start-03.png") == nil)
        #expect(poc.step(fileName: "poc-demo-vm-stop-final.png") == nil)
        #expect(poc.title(fileName: "poc-demo-vm-stop-03.png") == "poc-demo-vm-stop  step 3")
        #expect(poc.title(fileName: "other.png") == "poc-demo-vm-stop")
    }

    @Test func stepFromTimestampCapture() throws {
        let poc = try #require(PocCase(folderName: "poc-demo-vm-stop"))
        let step = poc.step(fileName: "scap-2026-10-25-143012.png")
        #expect(step == .timestamp(year: 2026, month: 10, day: 25, hour: 14, minute: 30, second: 12))
        #expect(step?.description == "2026-10-25 14:30:12")
        #expect(poc.step(fileName: "scap-2026-13-25-143012.png") == nil)
        #expect(poc.step(fileName: "scap-2026-10-25-253012.png") == nil)
        #expect(poc.step(fileName: "scap-2026-10-25.png") == nil)
    }

    @Test func stepFromTimestampAnyPrefix() throws {
        let poc = try #require(PocCase(folderName: "poc-demo-vm-stop"))
        let step = PocCase.Step.timestamp(year: 2026, month: 10, day: 25, hour: 14, minute: 30, second: 12)
        #expect(poc.step(fileName: "shot-2026-10-25-143012.png") == step)
        #expect(poc.step(fileName: "capture-2026-10-25-143012.png") == step)
        #expect(poc.step(fileName: "-2026-10-25-143012.png") == nil)
        #expect(poc.step(fileName: "Scap-2026-10-25-143012.png") == nil)
        #expect(poc.step(fileName: "scap 2026-10-25-143012.png") == nil)
    }
}
