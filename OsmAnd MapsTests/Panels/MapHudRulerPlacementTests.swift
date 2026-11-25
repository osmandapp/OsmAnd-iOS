import XCTest
import OsmAndShared

final class MapHudRulerPlacementTests: XCTestCase {

    // iPhone 17 in portrait: 402 x 874 pt in cells of 8 pt
    private let gridWidth: Int32 = 50
    private let gridHeight: Int32 = 109

    // osmandapp/OsmAnd#26820: the ruler width follows the zoom, its position must not
    func testRulerStaysInFirstHoleWhenExtraButtonLeavesNoRoom() {
        for rulerWidth in Int32(7)...15 {
            let ruler = ButtonPositionSize(id: "map_ruler", sz8dp: rulerWidth, left: true, top: false)
                .setSize(width8dp: rulerWidth, height8dp: 3)
                .setMoveHorizontal()
            let buttons = [
                ButtonPositionSize(id: "map.view.zoom_out", sz8dp: 7, left: false, top: false).setMoveVertical(),
                ButtonPositionSize(id: "map.view.zoom_id", sz8dp: 7, left: false, top: false).setMoveVertical(),
                ButtonPositionSize(id: "map.view.back_to_loc", sz8dp: 7, left: false, top: false).setMoveHorizontal(),
                ButtonPositionSize(id: "map.view.menu", sz8dp: 7, left: true, top: false).setMoveHorizontal(),
                ButtonPositionSize(id: "map.view.route_planning", sz8dp: 7, left: true, top: false).setMoveHorizontal(),
                ButtonPositionSize(id: "quick_actions", sz8dp: 7, left: false, top: false)
                    .setMargin(marginX: 16, marginY: 0)
                    .setMoveHorizontal(),
                ruler
            ]

            ButtonPositionSize.companion.computeNonOverlap(space: 1, buttons: buttons, totalWidth: gridWidth, totalHeight: gridHeight)

            XCTAssertEqual(ruler.marginX, 16, "rulerWidth=\(rulerWidth)")
        }
    }
}
