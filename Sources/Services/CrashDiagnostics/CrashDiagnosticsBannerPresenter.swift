//
//  CrashDiagnosticsBannerPresenter.swift
//  OsmAnd Maps
//

import UIKit

final class CrashDiagnosticsBannerPresenter {
    static let shared = CrashDiagnosticsBannerPresenter()

    private weak var banner: UIView?
    private var reportID: String?

    private init() {}

    func present(reportID: String) {
        guard banner == nil, let window = keyWindow() else { return }
        self.reportID = reportID

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.18
        container.layer.shadowRadius = 8
        container.layer.shadowOffset = CGSize(width: 0, height: 3)
        container.accessibilityViewIsModal = false

        let openButton = UIButton(type: .system)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.contentHorizontalAlignment = .leading
        openButton.titleLabel?.numberOfLines = 2
        openButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        openButton.setTitle(localizedString("crash_diagnostics_banner"), for: .normal)
        openButton.addTarget(self, action: #selector(openReport), for: .touchUpInside)

        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.accessibilityLabel = localizedString("crash_diagnostics_later")
        closeButton.addTarget(self, action: #selector(dismissBanner), for: .touchUpInside)

        container.addSubview(openButton)
        container.addSubview(closeButton)
        window.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -16),
            openButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            openButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            openButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            openButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            closeButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        banner = container

        container.alpha = 0
        container.transform = CGAffineTransform(translationX: 0, y: -20)
        UIView.animate(withDuration: 0.25) {
            container.alpha = 1
            container.transform = .identity
        }
        UIAccessibility.post(notification: .announcement, argument: localizedString("crash_diagnostics_banner"))
    }

    @objc private func openReport() {
        guard let reportID else {
            dismissBanner()
            return
        }
        dismissBanner()
        let diagnostics = CrashDiagnosticsViewController(reportIDToOpen: reportID)
        guard let presenter = topViewController() else { return }
        if let navigationController = presenter.navigationController {
            navigationController.pushViewController(diagnostics, animated: true)
        } else {
            presenter.present(UINavigationController(rootViewController: diagnostics), animated: true)
        }
    }

    @objc private func dismissBanner() {
        reportID = nil
        guard let banner else { return }
        UIView.animate(withDuration: 0.2, animations: {
            banner.alpha = 0
            banner.transform = CGAffineTransform(translationX: 0, y: -20)
        }, completion: { _ in
            banner.removeFromSuperview()
        })
    }

    private func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    private func topViewController() -> UIViewController? {
        var current = keyWindow()?.rootViewController
        while true {
            if let navigation = current as? UINavigationController {
                current = navigation.visibleViewController
            } else if let tab = current as? UITabBarController {
                current = tab.selectedViewController
            } else if let presented = current?.presentedViewController {
                current = presented
            } else {
                return current
            }
        }
    }
}
