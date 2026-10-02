//
//  OACrashReportPromptViewController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class OACrashReportPromptViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let iconSize: CGFloat = 104
        static let buttonMinimumHeight: CGFloat = 44
        static let buttonCornerRadius: CGFloat = 9
        static let bottomPadding: CGFloat = 16
    }

    var onDismiss: (() -> Void)?

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView(image: .icCustomCrashColored)
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let messageTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .scaledSystemFont(ofSize: 17, weight: .semibold)
        label.textColor = .textColorPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits.insert(.header)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .scaledSystemFont(ofSize: 15)
        label.textColor = .textColorPrimary
        label.textAlignment = .natural
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.baseForegroundColor = .buttonTextColorPrimary
        configuration.background.backgroundColor = .iconColorActive
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16)
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = Layout.buttonCornerRadius
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .scaledSystemFont(ofSize: 15, weight: .semibold)
            return outgoing
        }
        button.configuration = configuration
        button.configurationUpdateHandler = { button in
            button.alpha = button.isEnabled ? 1 : 0.45
        }
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(onSendTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var didFinish = false
    private var isSending = false

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureContent()
        applyLocalization()
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finish()
    }

    private func configureNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: localizedString("shared_string_cancel"),
            style: .plain,
            target: self,
            action: #selector(onCancelTapped)
        )

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemGroupedBackground
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.textColorPrimary,
            .font: UIFont.scaledSystemFont(ofSize: 17, weight: .semibold, maximumSize: 22)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .iconColorActive
    }

    private func configureContent() {
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(scrollView)
        scrollView.addSubview(iconView)
        scrollView.addSubview(messageTitleLabel)
        scrollView.addSubview(messageLabel)
        view.addSubview(sendButton)

        let paddedButtonBottomConstraint = sendButton.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: -Layout.bottomPadding
        )
        paddedButtonBottomConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -16),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            iconView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            iconView.centerXAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),

            messageTitleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            messageTitleLabel.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 48),
            messageTitleLabel.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -48),

            messageLabel.topAnchor.constraint(equalTo: messageTitleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Layout.horizontalPadding),
            messageLabel.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Layout.horizontalPadding),
            messageLabel.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -8),

            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalPadding),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalPadding),
            sendButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
            paddedButtonBottomConstraint,
            sendButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.buttonMinimumHeight)
        ])
    }

    private func applyLocalization() {
        title = localizedString("share_crash_log")

        messageTitleLabel.text = localizedString("crash_report_prompt_title")
        messageLabel.text = localizedString("crash_report_prompt_description")
        setSendButtonTitle(localizedString("shared_string_send"))
    }

    private func setSendButtonTitle(_ title: String) {
        sendButton.configuration?.title = title
    }

    @objc private func onCancelTapped() {
        dismiss(animated: true) { [weak self] in
            self?.finish()
        }
    }

    // uploads to osmand.net like Android does instead of asking where to share the files:
    // the share sheet made the user pick a mail app and most reports never left the device
    @objc private func onSendTapped() {
        guard !isSending else { return }
        isSending = true
        sendButton.isEnabled = false

        let reportURLs = OACrashDiagnosticsManager.shared.latestCrashReportURLs
        dismiss(animated: true) { [weak self] in
            self?.finish()
        }
        OACrashReportSender.sendCrashReport(reportURLs) { sent in
            guard let view = OARootViewController.instance().view else { return }
            OAUtilities.showToast(
                localizedString(sent ? "crash_report_sent" : "crash_report_send_failed"),
                details: nil,
                duration: 4,
                in: view
            )
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onDismiss?()
    }
}
