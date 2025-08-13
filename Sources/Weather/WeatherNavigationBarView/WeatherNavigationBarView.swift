@objcMembers
final class WeatherNavigationBarView: UIView {
    @IBOutlet private weak var leftButton: UIButton! {
        didSet {
            leftButton.setImage(UIImage.icNavbarChevron, for: .normal)
            leftButton.tintColor = .iconColorActive
        }
    }
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var rightButton: UIButton! {
        didSet {
            rightButton.setImage(UIImage.templateImageNamed("ic_navbar_settings"), for: .normal)
            rightButton.tintColor = .iconColorActive
            
            //temporarily hiding Data Source button
            rightButton.isHidden = true
            rightButton.isEnabled = false
        }
    }
    
    static var initView: WeatherNavigationBarView? {
        UINib(nibName: String(describing: self), bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as? WeatherNavigationBarView
    }
    
    var onLeftButtonAction: (() -> Void)?
    var onRightButtonAction: (() -> Void)?
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    
    @IBAction private func leftButtonTapped(_ sender: UIButton) {
        onLeftButtonAction?()
    }
    
    @IBAction private func rightButtonTapped(_ sender: UIButton) {
        onRightButtonAction?()
    }
}
