//
//  PreviewImageViewTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 09.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class PreviewImageViewTableViewCell: UITableViewCell {
    @IBOutlet private weak var previewImageButton: OAHudButton!
    @IBOutlet private weak var previewImageView: UIImageView!
    
    private let defaultImageSize: CGFloat = 30
    private let defaultImageOrigin: CGFloat = 9
    private let colorOnMapIconBackgroundColorLight: UIColor = .mapButtonBgColorDefault.light
    private let colorOnMapIconBackgroundColorDark: UIColor = .mapButtonBgColorDefault.dark
    private let colorPrimaryPurple: UIColor = .mapButtonIconColorActive.light
    private let colorPrimaryLightBlue: UIColor = .mapButtonIconColorActive.dark
    private let colorOnMapIconTintColorLight: UIColor = .mapButtonIconColorDefault.light
    private let colorOnMapIconTintColorDark: UIColor = .mapButtonIconColorDefault.dark
    private let colorOnMapIconBackgroundColorActive: UIColor = .mapButtonBgColorActive
    private let defaultBorderWidthNight: CGFloat = 2
    private let defaultShadowOpacity: Float = 1
    private let defaultShadowRadius: CGFloat = 12
    private let defaultShadowColor: CGColor = UIColor.black.withAlphaComponent(0.35).cgColor
    private let defaultShadowOffset = CGSize(width: 0, height: 2)
    
    func configure(appearanceParams: ButtonAppearanceParams?, buttonState: MapButtonState) {
        previewImageButton.buttonState = buttonState
        previewImageButton.setCustomAppearanceParams(appearanceParams)
        previewImageButton.translatesAutoresizingMaskIntoConstraints = true
        previewImageButton.center = contentView.center
        previewImageButton.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        setupImageViewWith(buttonState: buttonState, appearanceParams: appearanceParams)
        setupButtonColorWith(buttonState: buttonState)
        setupImageContainerShadow()
    }
    
    func rotateImage(_ angle: CGFloat) {
        previewImageView.transform = CGAffineTransform(rotationAngle: angle)
    }
    
    private func setupImageViewWith(buttonState: MapButtonState, appearanceParams: ButtonAppearanceParams?) {
        if isCompassButton(buttonState) {
            if !(previewImageView.superview is OAHudButton) {
                previewImageView.removeFromSuperview()
                previewImageButton.addSubview(previewImageView)
                previewImageView.translatesAutoresizingMaskIntoConstraints = true
                previewImageView.frame = CGRect(x: defaultImageOrigin, y: defaultImageOrigin, width: defaultImageSize, height: defaultImageSize)
            }
            previewImageView.image = previewImageButton.currentImage
            previewImageView.center = CGPoint(x: previewImageButton.frame.width / 2, y: previewImageButton.frame.height / 2)
            previewImageButton.setImage(nil, for: .normal)
            previewImageView.transform = CGAffineTransform(rotationAngle: -CGFloat(OARootViewController.instance().mapPanel.mapViewController.azimuth()) / 180.0 * CGFloat.pi)
        } else {
            previewImageView.isHidden = true
        }
    }
    
    private func isCompassButton(_ buttonState: MapButtonState) -> Bool {
        if buttonState is CompassButtonState {
            return true
        } else if let quickAction = buttonState as? QuickActionButtonState {
            return quickAction.quickActions.first?.getTypeId() == ChangeMapOrientationAction.getType().stringId && quickAction.isSingleAction()
        } else {
            return false
        }
    }
    
    private func setupButtonColorWith(buttonState: MapButtonState) {
        if buttonState is MapSettingsButtonState {
            let mode = OAAppSettings.sharedManager().applicationMode.get()
            previewImageButton.tintColorDay = mode.getProfileColor()
            previewImageButton.tintColorNight = mode.getProfileColor()
            previewImageButton.updateColors(forPressedState: false)
        } else if buttonState is DriveModeButtonState {
            guard let routingHelper = OARoutingHelper.sharedInstance() else { return }
            let routePlanningMode = routingHelper.isRoutePlanningMode() || ((routingHelper.isRouteCalculated() || routingHelper.isRouteBeingCalculated()) && !routingHelper.isFollowingMode())
            
            if routingHelper.isFollowingMode() || routePlanningMode {
                previewImageButton.tintColorDay = colorPrimaryPurple
                previewImageButton.tintColorNight = colorPrimaryLightBlue
            } else {
                previewImageButton.tintColorDay = colorOnMapIconTintColorLight
                previewImageButton.tintColorNight = colorOnMapIconTintColorDark
            }

            previewImageButton.updateColors(forPressedState: false)
        } else if buttonState is MyLocationButtonState {
            if OARootViewController.instance().mapPanel.hudViewController?.isLocationAvailable() == true {
                switch OsmAndApp.swiftInstance().mapMode {
                case .free:
                    previewImageButton.unpressedColorDay = colorOnMapIconBackgroundColorActive
                    previewImageButton.unpressedColorNight = colorOnMapIconBackgroundColorActive
                    previewImageButton.tintColorDay = .white
                    previewImageButton.tintColorNight = .white
                    previewImageButton.borderWidthNight = 0
                case .positionTrack:
                    previewImageButton.unpressedColorDay = colorOnMapIconBackgroundColorLight
                    previewImageButton.unpressedColorNight = colorOnMapIconBackgroundColorDark
                    previewImageButton.tintColorDay = colorPrimaryPurple
                    previewImageButton.tintColorNight = colorPrimaryLightBlue
                    previewImageButton.borderWidthNight = defaultBorderWidthNight
                default:
                    break
                }
            } else {
                previewImageButton.unpressedColorDay = colorOnMapIconBackgroundColorLight
                previewImageButton.unpressedColorNight = colorOnMapIconBackgroundColorDark
                previewImageButton.tintColorDay = colorOnMapIconTintColorLight
                previewImageButton.tintColorNight = colorOnMapIconTintColorDark
                previewImageButton.borderWidthNight = defaultBorderWidthNight
            }
            
            previewImageButton.updateColors(forPressedState: false)
        }
    }
    
    private func setupImageContainerShadow() {
        let shadowPath = UIBezierPath(roundedRect: previewImageButton.bounds, cornerRadius: previewImageButton.layer.cornerRadius)
        previewImageButton.layer.shadowPath = shadowPath.cgPath
        previewImageButton.layer.shadowColor = defaultShadowColor
        previewImageButton.layer.shadowOpacity = defaultShadowOpacity
        previewImageButton.layer.shadowRadius = defaultShadowRadius
        previewImageButton.layer.shadowOffset = defaultShadowOffset
    }
}
