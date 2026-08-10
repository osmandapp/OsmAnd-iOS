import UIKit

final class HorizontalEmptyCell: UITableViewCell {

    enum ContainerStyle {
        case grouped
        case card
    }

    private enum Layout {
        static let cornerRadius: CGFloat = 24
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 20
        static let textSpacing: CGFloat = 6
        static let iconSpacing: CGFloat = 16
        static let trailingSize: CGFloat = 30
        static let minimumActionRowHeight: CGFloat = 50
        static let actionVerticalInset: CGFloat = 14
    }

    private final class ActionRow: UIControl {
        private let titleLabel = UILabel()
        private var action: (() -> Void)?

        override var isHighlighted: Bool {
            didSet {
                backgroundColor = isHighlighted ? .buttonBgColorTap : .clear
            }
        }

        init() {
            super.init(frame: .zero)
            setupView()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func configure(title: String) {
            titleLabel.text = title
            accessibilityLabel = title
        }

        func updateAction(_ action: (() -> Void)?) {
            self.action = action
        }

        private func setupView() {
            isAccessibilityElement = true
            accessibilityTraits = .button

            titleLabel.font = .preferredFont(forTextStyle: .body)
            titleLabel.textColor = .textColorActive
            titleLabel.numberOfLines = 0
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.adjustsFontForContentSizeCategory = true
            titleLabel.isUserInteractionEnabled = false
            titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(titleLabel)

            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Layout.actionVerticalInset),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Layout.horizontalInset),
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.actionVerticalInset)
            ])
            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        }

        @objc private func handleTap() {
            action?()
        }
    }

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let trailingContainer = UIView()
    private let iconView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let separatorView = UIView()
    private let actionRow = ActionRow()

    private var descriptionBottomConstraint: NSLayoutConstraint?
    private var actionConstraints: [NSLayoutConstraint] = []
    private var cardLeadingConstraint: NSLayoutConstraint?
    private var cardTrailingConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
        actionRow.updateAction(nil)
        spinner.stopAnimating()
    }

    func configure(title: String,
                   description: String,
                   icon: UIImage?,
                   iconTint: UIColor,
                   actionTitle: String? = nil,
                   isSpinner: Bool = false,
                   containerStyle: ContainerStyle = .grouped,
                   action: (() -> Void)? = nil) {
        titleLabel.text = title
        descriptionLabel.text = description
        titleLabel.accessibilityLabel = [title, description].joined(separator: ". ")

        updateContainerStyle(containerStyle)
        updateTrailingContent(icon: icon, iconTint: iconTint, isSpinner: isSpinner)
        updateAction(title: actionTitle, action: action)
    }

    private func setupView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .groupBg
        cardView.clipsToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .textColorSecondary
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        descriptionLabel.isAccessibilityElement = false

        iconView.contentMode = .scaleAspectFit
        iconView.isAccessibilityElement = false
        spinner.isAccessibilityElement = false
        separatorView.backgroundColor = .customSeparator

        [titleLabel, descriptionLabel, trailingContainer, separatorView, actionRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }
        [iconView, spinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            trailingContainer.addSubview($0)
        }

        let descriptionBottomConstraint = descriptionLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor,
                                                                                     constant: -Layout.verticalInset)
        descriptionBottomConstraint.priority = UILayoutPriority(999)
        let cardLeadingConstraint = cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        let cardTrailingConstraint = cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        self.descriptionBottomConstraint = descriptionBottomConstraint
        self.cardLeadingConstraint = cardLeadingConstraint
        self.cardTrailingConstraint = cardTrailingConstraint

        let actionRowBottomConstraint = actionRow.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        actionRowBottomConstraint.priority = UILayoutPriority(999)
        actionConstraints = [
            separatorView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: Layout.verticalInset),
            separatorView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: Layout.horizontalInset),
            separatorView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -Layout.horizontalInset),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            actionRow.topAnchor.constraint(equalTo: separatorView.bottomAnchor),
            actionRow.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            actionRow.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            actionRowBottomConstraint,
            actionRow.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.minimumActionRowHeight)
        ]

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardLeadingConstraint,
            cardTrailingConstraint,
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            trailingContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: Layout.verticalInset),
            trailingContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -Layout.horizontalInset),
            trailingContainer.widthAnchor.constraint(equalToConstant: Layout.trailingSize),
            trailingContainer.heightAnchor.constraint(equalToConstant: Layout.trailingSize),

            iconView.topAnchor.constraint(equalTo: trailingContainer.topAnchor),
            iconView.leadingAnchor.constraint(equalTo: trailingContainer.leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: trailingContainer.trailingAnchor),
            iconView.bottomAnchor.constraint(equalTo: trailingContainer.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: trailingContainer.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: trailingContainer.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: Layout.verticalInset),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: Layout.horizontalInset),
            titleLabel.trailingAnchor.constraint(equalTo: trailingContainer.leadingAnchor, constant: -Layout.iconSpacing),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.textSpacing),
            descriptionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: Layout.horizontalInset),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingContainer.leadingAnchor, constant: -Layout.iconSpacing),
            descriptionBottomConstraint
        ])
    }

    private func updateContainerStyle(_ containerStyle: ContainerStyle) {
        let usesCardStyle = containerStyle == .card
        let inset = usesCardStyle ? Layout.horizontalInset : 0
        backgroundColor = usesCardStyle ? .clear : .groupBg
        contentView.backgroundColor = .clear
        cardView.backgroundColor = usesCardStyle ? .groupBg : .clear
        cardView.layer.cornerRadius = usesCardStyle ? Layout.cornerRadius : 0
        cardLeadingConstraint?.constant = inset
        cardTrailingConstraint?.constant = -inset
    }

    private func updateTrailingContent(icon: UIImage?, iconTint: UIColor, isSpinner: Bool) {
        spinner.isHidden = !isSpinner
        iconView.isHidden = isSpinner

        if isSpinner {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            iconView.image = icon?.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = iconTint
        }
    }

    private func updateAction(title: String?, action: (() -> Void)?) {
        guard let title, let action else {
            actionRow.updateAction(nil)
            separatorView.isHidden = true
            actionRow.isHidden = true
            NSLayoutConstraint.deactivate(actionConstraints)
            descriptionBottomConstraint?.isActive = true
            return
        }

        actionRow.configure(title: title)
        actionRow.updateAction(action)
        separatorView.isHidden = false
        actionRow.isHidden = false
        descriptionBottomConstraint?.isActive = false
        NSLayoutConstraint.activate(actionConstraints)
    }
}
