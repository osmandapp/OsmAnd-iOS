import UIKit

final class NavbarBlueButton: UIButton {

    private static let buttonHeight: CGFloat = 44
    private static let pillHorizontalInset: CGFloat = 14

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        if title(for: .normal)?.isEmpty == false {
            size.width += Self.pillHorizontalInset * 2
        }
        return size
    }

    static func pillBarButtonItem(title: String, target: Any?, action: Selector) -> UIBarButtonItem {
        let button = NavbarBlueButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .highlighted)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.addTarget(target, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        return button.wrappedInBarButtonItem()
    }

    static func circleBarButtonItem(image: UIImage?, target: Any?, action: Selector) -> UIBarButtonItem {
        let button = NavbarBlueButton(type: .custom)
        button.setImage(image?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: buttonHeight),
            button.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
        return button.wrappedInBarButtonItem()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    private func wrappedInBarButtonItem() -> UIBarButtonItem {
        backgroundColor = .systemBlue
        layer.masksToBounds = true
        let item = UIBarButtonItem(customView: self)
        if #available(iOS 26.0, *) {
            item.hidesSharedBackground = true
        }
        return item
    }
}
