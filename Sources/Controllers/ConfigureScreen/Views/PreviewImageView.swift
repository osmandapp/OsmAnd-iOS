//
//  PreviewImageView.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 09.02.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class PreviewImageView: UIView {
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
    
    func configure(appearanceParams: ButtonAppearanceParams?, buttonState: MapButtonState) {
        previewImageButton.buttonState = buttonState
        previewImageButton.setCustomAppearanceParams(appearanceParams)
        previewImageButton.translatesAutoresizingMaskIntoConstraints = true
        previewImageButton.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        previewImageButton.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        setupImageViewWith(buttonState: buttonState, appearanceParams: appearanceParams)
        setupButtonColorWith(buttonState: buttonState)
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
}
