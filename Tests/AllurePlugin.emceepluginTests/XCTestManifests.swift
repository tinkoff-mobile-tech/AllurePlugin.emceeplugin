import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AllurePlugin_emceepluginTests.allTests),
    ]
}
#endif
