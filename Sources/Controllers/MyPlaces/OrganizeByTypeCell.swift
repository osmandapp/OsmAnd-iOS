import UIKit

final class OrganizeByTypeCell: UITableViewCell {

    static let cellReuseIdentifier = "OrganizeByTypeCell"

    static let minHeight: CGFloat = 52
    private static let leadingInset: CGFloat = 16
    private static let checkmarkSize: CGFloat = 20
    private static let iconSize: CGFloat = 28
    private static let gap: CGFloat = 8
    private static let verticalPadding: CGFloat = 12

    var onProBadgeTapped: (() -> Void)?

    private let checkmarkView = UIImageView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    private lazy var proBadgeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(.icPaymentLabelPro, for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(proBadgeButtonPressed), for: .touchUpInside)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        checkmarkView.contentMode = .scaleAspectFit
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkmarkView)

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        let lead = Self.leadingInset
        let cSize = Self.checkmarkSize
        let iSize = Self.iconSize
        let gap = Self.gap
        let vPad = Self.verticalPadding

        NSLayoutConstraint.activate([
            checkmarkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: lead),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: cSize),
            checkmarkView.heightAnchor.constraint(equalToConstant: cSize),

            iconView.leadingAnchor.constraint(equalTo: checkmarkView.trailingAnchor, constant: gap),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: iSize),
            iconView.heightAnchor.constraint(equalToConstant: iSize),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: gap),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -lead),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: vPad),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -vPad),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minHeight)
        ])
    }

    func configure(title: String?, icon: UIImage?, isSelected: Bool, isLocked: Bool) {
        separatorInset = UIEdgeInsets(top: 0, left: Self.leadingInset + Self.checkmarkSize + Self.gap + Self.iconSize + Self.gap, bottom: 0, right: Self.leadingInset)
        titleLabel.text = title
        titleLabel.textColor = .textColorPrimary

        iconView.image = icon
        iconView.tintColor = isSelected ? .iconColorActive : .iconColorDefault

        checkmarkView.image = isSelected ? .templateImageNamed("ic_checkmark_default") : nil
        checkmarkView.tintColor = .iconColorActive

        accessoryType = .none
        accessoryView = isLocked ? proBadgeButton : nil
        selectionStyle = .default
    }

    @objc private func proBadgeButtonPressed() {
        onProBadgeTapped?()
    }
}
