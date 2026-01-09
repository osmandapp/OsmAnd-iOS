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
    @IBOutlet private weak var sizeConstraint: NSLayoutConstraint!
    
    private let defaultImageSize: CGFloat = 30
    private let defaultImageOrigin: CGFloat = 9
    
    func configure(appearanceParams: ButtonAppearanceParams?, buttonState: MapButtonState) {
        previewImageButton.buttonState = buttonState
        previewImageButton.setCustomAppearanceParams(appearanceParams)
        setupImageViewWith(buttonState: buttonState, appearanceParams: appearanceParams)
        setupButtonColorWith(buttonState: buttonState)
        sizeConstraint.constant = previewImageButton.frame.width
        setupImageContainerShadow()
    }
    
    func rotateImage(_ angle: CGFloat) {
        previewImageView.transform = CGAffineTransform(rotationAngle: angle)
    }
    
    private func setupImageViewWith(buttonState: MapButtonState, appearanceParams: ButtonAppearanceParams?) {
        if buttonState is CompassButtonState || (buttonState is QuickActionButtonState && (buttonState as! QuickActionButtonState).quickActions.first?.getTypeId() == ChangeMapOrientationAction.getType().stringId && (buttonState as! QuickActionButtonState).isSingleAction() == true) {
            if !(previewImageView.superview is OAHudButton) {
                previewImageView.removeFromSuperview()
                previewImageButton.addSubview(previewImageView)
                previewImageView.translatesAutoresizingMaskIntoConstraints = true
                previewImageView.frame = CGRect(x: defaultImageOrigin, y: defaultImageOrigin, width: defaultImageSize, height: defaultImageSize)
            }
            previewImageView.image = previewImageButton.currentImage
            previewImageView.center = CGPoint(x: previewImageButton.frame.width / 2, y: previewImageButton.frame.height / 2)
            previewImageButton.setImage(nil, for: .normal)
        } else {
            previewImageView.isHidden = true
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
            var routePlanningMode = false
            if routingHelper.isRoutePlanningMode() {
                routePlanningMode = true
            } else if (routingHelper.isRouteCalculated() || routingHelper.isRouteBeingCalculated()) && !routingHelper.isFollowingMode() {
                routePlanningMode = true
            }
            
            if routingHelper.isFollowingMode() || routePlanningMode {
                previewImageButton.tintColorDay = UIColor(rgb: 0x5714CC)
                previewImageButton.tintColorNight = UIColor(rgb: 0x7499F1)
            } else {
                previewImageButton.tintColorDay = UIColor(rgb: 0x545454)
                previewImageButton.tintColorNight = UIColor(rgb: 0xcccccc)
            }

            previewImageButton.updateColors(forPressedState: false)
        } else if buttonState is MyLocationButtonState {
            if OARootViewController.instance().mapPanel.hudViewController?.isLocationAvailable() == true {
                switch OsmAndApp.swiftInstance().mapMode {
                case .free:
                    previewImageButton.unpressedColorDay = UIColor(rgb: 0x682AD5)
                    previewImageButton.unpressedColorNight = UIColor(rgb: 0x682AD5)
                    previewImageButton.tintColorDay = .white
                    previewImageButton.tintColorNight = .white
                    previewImageButton.borderWidthNight = 0
                case .positionTrack:
                    previewImageButton.unpressedColorDay = UIColor(rgb: 0xFFFFFF)
                    previewImageButton.unpressedColorNight = UIColor(rgb: 0x3F3F3F)
                    previewImageButton.tintColorDay = UIColor(rgb: 0x5714CC)
                    previewImageButton.tintColorNight = UIColor(rgb: 0x7499F1)
                    previewImageButton.borderWidthNight = 2
                default:
                    break
                }
            } else {
                previewImageButton.unpressedColorDay = UIColor(rgb: 0xFFFFFF)
                previewImageButton.unpressedColorNight = UIColor(rgb: 0x3F3F3F)
                previewImageButton.tintColorDay = UIColor(rgb: 0x545454)
                previewImageButton.tintColorNight = UIColor(rgb: 0xcccccc)
                previewImageButton.borderWidthNight = 2
            }
            
            previewImageButton.updateColors(forPressedState: false)
        }
    }
    
    private func setupImageContainerShadow() {
        let shadowPath = UIBezierPath(roundedRect: previewImageButton.bounds, cornerRadius: previewImageButton.layer.cornerRadius)
        previewImageButton.layer.shadowPath = shadowPath.cgPath
        previewImageButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.35).cgColor
        previewImageButton.layer.shadowOpacity = 1
        previewImageButton.layer.shadowRadius = 12
        previewImageButton.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
}
