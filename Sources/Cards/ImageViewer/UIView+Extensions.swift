import UIKit

extension UIView {
    func bindFrameToSuperview(top: CGFloat = 0,
                              leading: CGFloat = 0,
                              trailing: CGFloat = 0,
                              bottom: CGFloat = 0) {
        guard let superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: superview.topAnchor, constant: top).isActive = true
        leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: leading).isActive = true
        superview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: trailing).isActive = true
        superview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: bottom).isActive = true
    }
    
    func bindFrameToSuperview(margin: CGFloat) {
        bindFrameToSuperview(top: margin, leading: margin, trailing: margin, bottom: margin)
    }
    
    func frameRelativeToWindow() -> CGRect {
        convert(bounds, to: nil)
    }
}
