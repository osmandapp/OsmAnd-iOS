import UIKit

final class OpeningHoursCollapsableView: OACollapsableLabelView {
    private static let initialFrame = CGRect(x: 0, y: 0, width: 320, height: 100)

    init(checkDate: String, collapsed: Bool) {
        super.init(frame: Self.initialFrame)
        self.collapsed = collapsed
        setText(checkDate)
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .textColorSecondary
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
