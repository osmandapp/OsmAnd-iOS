import XCTest
@testable import OsmAnd_Maps

final class Model3dHelperTests: XCTestCase {

    func testPureModelNameStripsLeadingPrefix() {
        XCTAssertEqual(Model3dHelper.pureModelName("model_Car"), "Car")
    }

    func testPureModelNameKeepsPrefixInsideFolderName() {
        XCTAssertEqual(Model3dHelper.pureModelName("model_my_model_car"), "my_model_car")
    }

    func testPureModelNameWithoutPrefix() {
        XCTAssertEqual(Model3dHelper.pureModelName("my_model_car"), "my_model_car")
    }

    func testPureModelNameUsesLastPathComponent() {
        XCTAssertEqual(Model3dHelper.pureModelName("models/model_Car"), "Car")
    }
}
