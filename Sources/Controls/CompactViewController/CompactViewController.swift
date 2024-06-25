//
//  CompactViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 24.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class CompactNavigationViewController: UINavigationController {
//    override func loadView() {
//    //    view = WeatherView()
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

@objcMembers
final class CompactViewController: UIViewController {
    
    struct Config {
        struct StackButtonsConfig {
            var spacing: CGFloat
            var leftSpace: CGFloat
            var landscapeBottomSpace: CGFloat
        }
        
        var stackButtonsConfig: StackButtonsConfig
        var maxWidth: CGFloat
        
        static let defaultConfig = Config(stackButtonsConfig: Config.StackButtonsConfig(spacing: 16, leftSpace: 20, landscapeBottomSpace: 20), maxWidth: 320)
    }
    
    private var config: Config = .defaultConfig
    private var controller: UIViewController!
    private var buttonsStackLeadingConstraint: NSLayoutConstraint?
    private var buttonsStackBottomConstraint: NSLayoutConstraint?
    
    private lazy var buttonsStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = config.stackButtonsConfig.spacing
        stackView.layer.borderWidth = 1.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Life circle
    
//    override func loadView() {
//       // super.loadView()
//        view = WeatherView()
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yellow
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureButtonsStackView()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        controller?.remove()
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            let isLandscape = UIDevice.current.orientation.isLandscape
            add(controller, frame: .init(x: 0, y: 0, width: isLandscape ? config.maxWidth : view.frame.width, height: view.frame.height))
            configureButtonsStackView()
            if isLandscape {
                print("Landscape")
                buttonsStackLeadingConstraint?.constant = config.maxWidth
                buttonsStackBottomConstraint?.constant = config.stackButtonsConfig.landscapeBottomSpace
            } else {
                print("Portrait")
                buttonsStackLeadingConstraint?.constant = config.stackButtonsConfig.leftSpace
                buttonsStackBottomConstraint?.constant = -250
            }
        })
    }
    
//    override func willTransition(to newCollection: UITraitCollection, with coordinator: any UIViewControllerTransitionCoordinator) {
//        super.willTransition(to: newCollection, with: coordinator)
//        controller?.remove()
//        
//        coordinator.animate(alongsideTransition: { [weak self] _ in
//            guard let self else { return }
//            let isLandscape = UIDevice.current.orientation.isLandscape
//            add(controller, frame: .init(x: 0, y: 0, width: isLandscape ? config.maxWidth : view.frame.width, height: view.frame.height))
//            configureButtonsStackView()
//            if isLandscape {
//                print("Landscape")
//                buttonsStackLeadingConstraint?.constant = config.maxWidth
//                buttonsStackBottomConstraint?.constant = config.stackButtonsConfig.landscapeBottomSpace
//            } else {
//                print("Portrait")
//                buttonsStackLeadingConstraint?.constant = config.stackButtonsConfig.leftSpace
//                buttonsStackBottomConstraint?.constant = -200
//            }
//        })
//    }
    
    // MARK: - Public func
    func addController(controller: UIViewController) {
        self.controller = controller
        add(controller, frame: .init(x: 0, y: 0, width: UIDevice.current.orientation.isLandscape ? config.maxWidth : view.frame.width, height: view.frame.height))
    }
    
    func addButtons(buttons: [UIButton]) {
        buttons.forEach { button in
            button.layer.borderWidth = 1.0
            buttonsStack.addArrangedSubview(button)
        }
    }
    
    func applyConfig(config: Config) {
        self.config = config
    }
    
    // MARK: - Private func
    private func configureButtonsStackView() {
        buttonsStack.removeFromSuperview()
        buttonsStackLeadingConstraint = nil
        buttonsStackBottomConstraint = nil
        if UIDevice.current.orientation.isLandscape {
            view.addSubview(buttonsStack)
            configureButtonsStackViewConstraint(view: view)
        } else {
            if let nvc = controller as? UINavigationController, let firstViewController = nvc.viewControllers.first {
                firstViewController.view.addSubview(buttonsStack)
                configureButtonsStackViewConstraint(view: firstViewController.view)
            } else {
                controller.view.addSubview(buttonsStack)
                configureButtonsStackViewConstraint(view: controller.view)
            }
        }
    }
    
    private func configureButtonsStackViewConstraint(view: UIView) {
        buttonsStackLeadingConstraint = buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIDevice.current.orientation.isLandscape ? config.maxWidth : config.stackButtonsConfig.leftSpace )
        buttonsStackLeadingConstraint?.isActive = true
        
        buttonsStackBottomConstraint = buttonsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant:  UIDevice.current.orientation.isLandscape ? config.stackButtonsConfig.landscapeBottomSpace : -250)
        buttonsStackBottomConstraint?.isActive = true
    }
}
