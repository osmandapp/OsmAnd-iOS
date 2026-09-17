//
//  GetElevationDataViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 25.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

private enum GetElevationDataSheetLayout {
    static let panelWidth: CGFloat = 393
    static let horizontalInset: CGFloat = 16
    static let phoneTopInset: CGFloat = 20
    static let padTopInset: CGFloat = 8
    static let verticalInset: CGFloat = 16
    static let minimumMapWidth: CGFloat = 252
    static let cornerRadius: CGFloat = 20
    static let animationDuration: TimeInterval = 0.3
    static let dimmingAlpha: CGFloat = 0.2
}

final class GetElevationDataViewController: UIViewController {

    var onSelectMethod: ((Bool) -> Void)?

    private let isTerrainMapsAvailable: Bool
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let separatorView = SeparatorView()
    private let sheetTransitioningDelegate = GetElevationDataSheetTransitioningDelegate()

    init(isTerrainMapsAvailable: Bool) {
        self.isTerrainMapsAvailable = isTerrainMapsAvailable
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = sheetTransitioningDelegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.backgroundColor = .viewBg

        let closeButton = PlanRouteButtonFactory.iconButton(image: .icNavbarClose, size: 44)
        closeButton.layer.shadowOpacity = 0
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        view.addSubview(closeButton)

        titleLabel.text = localizedString("get_elevation_data")
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .textColorPrimary
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        descriptionLabel.text = localizedString("get_elevation_data_description")
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .textColorSecondary
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)

        let optionsCard = UIView()
        optionsCard.backgroundColor = .groupBg
        optionsCard.layer.cornerRadius = 24
        optionsCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(optionsCard)

        let nearbyRoadsRow = makeOptionRow(
            icon: .icCustomAttachTrack,
            title: localizedString("use_nearby_roads"),
            subtitle: localizedString("may_adjust_track_geometry"),
            useNearbyRoads: true
        )

        separatorView.translatesAutoresizingMaskIntoConstraints = false

        let terrainRow = makeOptionRow(
            icon: .icCustomTerrain,
            title: localizedString("use_terrain_maps"),
            subtitle: localizedString("track_geometry_stays_unchanged"),
            useNearbyRoads: false,
            accessoryImage: isTerrainMapsAvailable ? nil : .icPaymentLabelPro
        )

        [nearbyRoadsRow, separatorView, terrainRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            optionsCard.addSubview($0)
        }

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),

            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 32),
            descriptionLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),

            optionsCard.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            optionsCard.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            optionsCard.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            optionsCard.bottomAnchor.constraint(lessThanOrEqualTo: safeArea.bottomAnchor, constant: -16),

            nearbyRoadsRow.topAnchor.constraint(equalTo: optionsCard.topAnchor),
            nearbyRoadsRow.leadingAnchor.constraint(equalTo: optionsCard.leadingAnchor),
            nearbyRoadsRow.trailingAnchor.constraint(equalTo: optionsCard.trailingAnchor),

            separatorView.topAnchor.constraint(equalTo: nearbyRoadsRow.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: optionsCard.leadingAnchor, constant: 56),
            separatorView.trailingAnchor.constraint(equalTo: optionsCard.trailingAnchor, constant: -16),

            terrainRow.topAnchor.constraint(equalTo: separatorView.bottomAnchor),
            terrainRow.leadingAnchor.constraint(equalTo: optionsCard.leadingAnchor),
            terrainRow.trailingAnchor.constraint(equalTo: optionsCard.trailingAnchor),
            terrainRow.bottomAnchor.constraint(equalTo: optionsCard.bottomAnchor)
        ])
    }

    private func makeOptionRow(icon: UIImage?, title: String, subtitle: String, useNearbyRoads: Bool, accessoryImage: UIImage? = nil) -> UIView {
        let row = UIView()

        let iconView = UIImageView(image: icon)
        iconView.tintColor = .iconColorActive
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textColor = .textColorPrimary

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .textColorSecondary

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        [iconView, textStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview($0)
        }

        let textTrailingConstraint: NSLayoutConstraint
        if let accessoryImage {
            let accessoryView = UIImageView(image: accessoryImage)
            accessoryView.contentMode = .scaleAspectFit
            accessoryView.setContentCompressionResistancePriority(.required, for: .horizontal)
            accessoryView.setContentHuggingPriority(.required, for: .horizontal)
            accessoryView.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(accessoryView)
            NSLayoutConstraint.activate([
                accessoryView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                accessoryView.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16)
            ])
            textTrailingConstraint = textStack.trailingAnchor.constraint(lessThanOrEqualTo: accessoryView.leadingAnchor, constant: -16)
        } else {
            textTrailingConstraint = textStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            textTrailingConstraint,
            textStack.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12)
        ])

        let tapButton = UIButton(type: .custom)
        tapButton.addTarget(self, action: useNearbyRoads ? #selector(onNearbyRoads) : #selector(onTerrainMaps), for: .touchUpInside)
        tapButton.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(tapButton)

        NSLayoutConstraint.activate([
            tapButton.topAnchor.constraint(equalTo: row.topAnchor),
            tapButton.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            tapButton.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            tapButton.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])

        return row
    }

    @objc private func onClose() {
        dismiss(animated: true)
    }

    @objc private func onNearbyRoads() {
        dismiss(animated: true) { [weak self] in
            self?.onSelectMethod?(true)
        }
    }

    @objc private func onTerrainMaps() {
        guard OAIAPHelper.isOsmAndProAvailable() else {
            let choosePlanViewController = OAChoosePlanViewController(feature: OAFeature.terrain())
            let navController = UINavigationController(rootViewController: choosePlanViewController)
            navController.isNavigationBarHidden = true
            navController.edgesForExtendedLayout = []
            present(navController, animated: true)
            return
        }
        dismiss(animated: true) { [weak self] in
            self?.onSelectMethod?(false)
        }
    }
}

private final class GetElevationDataSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController,
                               presenting: UIViewController?,
                               source: UIViewController) -> UIPresentationController? {
        GetElevationDataSheetPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController,
                            presenting: UIViewController,
                            source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        GetElevationDataSheetAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        GetElevationDataSheetAnimator(isPresenting: false)
    }
}

private final class GetElevationDataSheetPresentationController: UIPresentationController {

    private lazy var dimmingView: UIView = {
        let dimming = UIView()
        dimming.backgroundColor = UIColor.black.withAlphaComponent(GetElevationDataSheetLayout.dimmingAlpha)
        dimming.alpha = 0
        dimming.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onDimmingTapped)))
        return dimming
    }()

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else { return .zero }
        return frame(for: containerView.bounds.size, safeArea: containerView.safeAreaInsets)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView else { return }
        containerView.accessibilityViewIsModal = true
        dimmingView.frame = containerView.bounds
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(dimmingView)
        if let presentedView {
            presentedView.layer.cornerRadius = GetElevationDataSheetLayout.cornerRadius
            presentedView.layer.masksToBounds = true
        }
        applyCornerMask(for: containerView.bounds.size)
        presentedViewController.transitionCoordinator?.animate { [weak self] _ in
            self?.dimmingView.alpha = 1
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentedViewController.transitionCoordinator?.animate { [weak self] _ in
            self?.dimmingView.alpha = 0
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        guard let containerView else { return }
        dimmingView.frame = containerView.bounds
        applyCornerMask(for: containerView.bounds.size)
        if presentedViewController.transitionCoordinator == nil {
            presentedView?.frame = frameOfPresentedViewInContainerView
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            guard let self, let containerView else { return }
            presentedView?.frame = frame(for: size, safeArea: containerView.safeAreaInsets)
            applyCornerMask(for: size)
        } completion: { [weak self] _ in
            guard let self, let containerView else { return }
            presentedView?.frame = frameOfPresentedViewInContainerView
            applyCornerMask(for: containerView.bounds.size)
        }
    }

    @objc private func onDimmingTapped() {
        presentingViewController.dismiss(animated: true)
    }

    private func isPhoneLandscape(_ size: CGSize) -> Bool {
        !OAUtilities.isIPad() && !OAUtilities.isiOSAppOnMac() && size.width > size.height
    }

    private func isSidePanel(for size: CGSize, safeArea: UIEdgeInsets) -> Bool {
        guard OAUtilities.isIPad() || OAUtilities.isiOSAppOnMac() || size.width > size.height else { return false }
        let leftInset = max(GetElevationDataSheetLayout.horizontalInset, safeArea.left)
        let visibleMapWidth = size.width - leftInset - GetElevationDataSheetLayout.panelWidth - safeArea.right
        return visibleMapWidth >= GetElevationDataSheetLayout.minimumMapWidth
    }

    private func frame(for size: CGSize, safeArea: UIEdgeInsets) -> CGRect {
        if isSidePanel(for: size, safeArea: safeArea) {
            let left = max(GetElevationDataSheetLayout.horizontalInset, safeArea.left)
            let top = isPhoneLandscape(size)
                ? max(GetElevationDataSheetLayout.phoneTopInset, safeArea.top)
                : safeArea.top + GetElevationDataSheetLayout.padTopInset
            let bottom = isPhoneLandscape(size)
                ? 0
                : max(GetElevationDataSheetLayout.verticalInset, safeArea.bottom)
            return CGRect(x: left,
                          y: top,
                          width: GetElevationDataSheetLayout.panelWidth,
                          height: max(0, size.height - top - bottom))
        }
        let contentHeight = measuredContentHeight(forWidth: size.width)
        let maxHeight = size.height - safeArea.top - 24
        let height = min(contentHeight + safeArea.bottom, maxHeight)
        return CGRect(x: 0, y: size.height - height, width: size.width, height: height)
    }

    private func measuredContentHeight(forWidth width: CGFloat) -> CGFloat {
        guard width > 0, let contentView = presentedViewController.view else { return 320 }
        let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let fitting = contentView.systemLayoutSizeFitting(target,
                                                          withHorizontalFittingPriority: .required,
                                                          verticalFittingPriority: .fittingSizeLevel)
        let insets = contentView.safeAreaInsets
        return max(160, ceil(fitting.height - insets.top - insets.bottom))
    }

    private func applyCornerMask(for size: CGSize) {
        guard let presentedView else { return }
        let roundsAllCorners = isSidePanel(for: size, safeArea: containerView?.safeAreaInsets ?? .zero)
            && !isPhoneLandscape(size)
        presentedView.layer.maskedCorners = roundsAllCorners
            ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            : [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
}

private final class GetElevationDataSheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        GetElevationDataSheetLayout.animationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        if isPresenting {
            guard let toViewController = transitionContext.viewController(forKey: .to),
                  let toView = transitionContext.view(forKey: .to) else {
                transitionContext.completeTransition(false)
                return
            }
            let finalFrame = transitionContext.finalFrame(for: toViewController)
            toView.frame = finalFrame
            toView.transform = offscreenTransform(for: finalFrame, in: container)
            container.addSubview(toView)
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
                toView.transform = .identity
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        } else {
            guard let fromView = transitionContext.view(forKey: .from) else {
                transitionContext.completeTransition(false)
                return
            }
            let targetTransform = offscreenTransform(for: fromView.frame, in: container)
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseIn], animations: {
                fromView.transform = targetTransform
            }, completion: { _ in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }

    private func offscreenTransform(for frame: CGRect, in container: UIView) -> CGAffineTransform {
        CGAffineTransform(translationX: 0, y: container.bounds.height - frame.minY)
    }
}
