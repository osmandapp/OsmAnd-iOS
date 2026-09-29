import UIKit

final class OpeningHoursCollapsableView: OACollapsableLabelView {
    init(checkDate: String, collapsed: Bool) {
        super.init(defaultParameters: collapsed)
        setText(checkDate)
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .textColorSecondary
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
