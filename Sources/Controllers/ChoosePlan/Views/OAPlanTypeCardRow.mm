//
//  OAPlanTypeCardRow.mm
//  OsmAnd
//
//  Created by Skalii on 20.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAPlanTypeCardRow.h"
#import "OAProducts.h"
#import "OAIAPHelper.h"
#import "OAAppSettings.h"
#import "OAChoosePlanHelper.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OAPlanTypeCardRow ()

@property (weak, nonatomic) IBOutlet UIImageView *imageViewLeftIcon;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewRightIcon;
@property (weak, nonatomic) IBOutlet UIView *badgeViewContainer;
@property (weak, nonatomic) IBOutlet UILabel *badgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *tertiaryDescrLabel;

@end

@implementation OAPlanTypeCardRow
{
    OAPlanTypeCardRowType _type;
    OAProduct *_subscription;

    UITapGestureRecognizer *_tapRecognizer;
    UILongPressGestureRecognizer *_longPressRecognizer;
}

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAPlanTypeCardRow class]])
        {
            self = (OAPlanTypeCardRow *)v;
            break;
        }

    if (self)
        self.frame = CGRectMake(0, 0, 200, 100);

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAPlanTypeCardRow class]])
        {
            self = (OAPlanTypeCardRow *)v;
            break;
        }

    if (self)
        self.frame = frame;

    return self;
}

- (instancetype)initWithType:(OAPlanTypeCardRowType)type
{
    self = [super init];
    if (self)
    {
        _type = type;
        [self commonInit];
        [self updateType];
    }
    return self;
}

- (void)commonInit
{
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapped:)];
    [self addGestureRecognizer:_tapRecognizer];
    _longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressed:)];
    _longPressRecognizer.minimumPressDuration = .2;
    [self addGestureRecognizer:_longPressRecognizer];
    self.layer.cornerRadius = 9.;
}

- (void)updateType
{
    switch (_type)
    {
        case EOAPlanTypeChoosePlan:
        {
            self.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
            self.imageViewLeftIcon.hidden = NO;
            self.imageViewRightIcon.hidden = YES;
            self.labelTitle.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
            self.labelDescription.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            self.labelTitle.textColor = [UIColor colorNamed:ACColorNameButtonTextColorSecondary];
            self.labelDescription.textColor = [UIColor colorNamed:ACColorNameButtonTextColorSecondary];
            self.labelTitle.textAlignment = NSTextAlignmentLeft;
            self.labelDescription.textAlignment = NSTextAlignmentLeft;
            break;
        }
        case EOAPlanTypeChooseSubscription:
        {
            self.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            self.imageViewLeftIcon.hidden = YES;
            self.imageViewRightIcon.hidden = NO;
            self.labelTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            self.labelDescription.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            self.labelTitle.textColor = [UIColor colorNamed:ACColorNameButtonTextColorSecondary];
            self.labelDescription.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            self.labelTitle.textAlignment = NSTextAlignmentLeft;
            self.labelDescription.textAlignment = NSTextAlignmentLeft;
            break;
        }
        case EOAPlanTypePurchase:
        {
            self.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorPrimary];
            self.imageViewLeftIcon.hidden = YES;
            self.imageViewRightIcon.hidden = YES;
            self.labelTitle.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
            self.labelDescription.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            self.labelTitle.textColor = [UIColor colorNamed:ACColorNameButtonTextColorPrimary];
            self.labelDescription.textColor = [UIColor colorNamed:ACColorNameButtonTextColorPrimary];
            self.labelTitle.textAlignment = NSTextAlignmentCenter;
            self.labelDescription.textAlignment = NSTextAlignmentCenter;
            break;
        }
    }
}

- (void)updateSelected:(BOOL)selected
{
    if (_type == EOAPlanTypeChooseSubscription)
    {
        self.layer.borderWidth = selected ? 2. : 0.;
        self.layer.borderColor = selected ? [UIColor colorNamed:ACColorNameButtonBgColorPrimary].CGColor : UIColor.clearColor.CGColor;
        self.imageViewRightIcon.image = selected ? [UIImage imageNamed:@"ic_system_checkbox_selected"] : [UIImage templateImageNamed: @"ic_custom_checkbox_unselected"];
        self.imageViewRightIcon.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
        self.backgroundColor = selected ? [UIColor colorNamed:ACColorNameButtonBgColorTertiary] : UIColor.clearColor;
        self.labelTitle.textColor = selected ? [UIColor colorNamed:ACColorNameButtonTextColorSecondary] : [UIColor colorNamed:ACColorNameTextColorActive];
    }
}

- (OAProductDiscount *)getDiscountOffer
{
    OAProductDiscount *discountOffer = nil;
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if (settings.eligibleForIntroductoryPrice)
    {
        discountOffer = _subscription.introductoryPrice;
    }
    else if (settings.eligibleForSubscriptionOffer)
    {
        if (_subscription.discounts && _subscription.discounts.count > 0)
            discountOffer = _subscription.discounts[0];
    }
    return discountOffer;
}

- (void)updateInfo:(OAProduct *)subscription selectedFeature:(OAFeature *)selectedFeature selected:(BOOL)selected
{
    _subscription = subscription;
    switch (_type)
    {
        case EOAPlanTypeChoosePlan:
        {
            BOOL isMaps = [OAIAPHelper isFullVersion:subscription] || ([subscription isKindOfClass:OASubscription.class] && [OAIAPHelper isMapsSubscription:(OASubscription *) subscription]);
            BOOL mapsPlusPurchased = [OAIAPHelper isSubscribedToMaps] || [OAIAPHelper isFullVersionPurchased];
            BOOL osmAndProPurchased = [OAIAPHelper isOsmAndProAvailable];
            BOOL isPurchased = (isMaps && mapsPlusPurchased) || osmAndProPurchased;
            BOOL available = ((isMaps && [selectedFeature isAvailableInMapsPlus]) || !isMaps) && !isPurchased;
            NSString *patternPlanAvailable = OALocalizedString(available ? @"continue_with" : @"not_available_with");
            self.labelTitle.text = isPurchased
                    ? OALocalizedString(@"shared_string_purchased")
                    : [NSString stringWithFormat:patternPlanAvailable, _subscription.localizedTitle];

            self.labelDescription.text = isPurchased
                    ? @""
                    : [NSString stringWithFormat:@"%@ %@",
                            [OAUtilities capitalizeFirstLetter:OALocalizedString(@"shared_string_from")],
                            _subscription.formattedPrice];

            NSString *iconName = [_subscription productIconName];
            UIImage *icon;
            if (!available)
                icon = [UIImage imageNamed:[iconName stringByAppendingString:@"_bw"]];
            if (!icon)
                icon = [UIImage imageNamed:iconName];
            self.imageViewLeftIcon.image = icon;
            self.imageViewRightIcon.image = nil;
            self.backgroundColor = available && !isPurchased ? [UIColor colorNamed:ACColorNameButtonBgColorTertiary] : [UIColor colorNamed:ACColorNameButtonBgColorSecondary];
            self.labelTitle.textColor = available && !isPurchased ? [UIColor colorNamed:ACColorNameButtonTextColorSecondary] : [UIColor colorNamed:ACColorNameTextColorSecondary];
            self.labelDescription.textColor = available && !isPurchased ? [UIColor colorNamed:ACColorNameButtonTextColorSecondary] : [UIColor colorNamed:ACColorNameTextColorSecondary];
            self.userInteractionEnabled = available && !isPurchased;
            self.layer.borderWidth = 0.;
            break;
        }
        case EOAPlanTypeChooseSubscription:
        {
            OAProductDiscount * discountOffer = [self getDiscountOffer];
            
            BOOL hasSpecialOffer = discountOffer != nil;
            
            NSAttributedString *purchaseDescr = [_subscription getDescription:15.0];
            NSMutableAttributedString *descr = [[NSMutableAttributedString alloc] initWithString:@""];
            if (hasSpecialOffer)
            {
                [descr appendAttributedString:[[NSAttributedString alloc]
                                                                 initWithString:discountOffer.getDescriptionTitle
                                                                 attributes:@{NSFontAttributeName:[UIFont scaledSystemFontOfSize:15 weight:UIFontWeightSemibold]}]];
            }
            else if (purchaseDescr)
            {
                [descr appendAttributedString:purchaseDescr];
            }
            
            if (descr.length > 0)
            {
                _badgeViewContainer.hidden = NO;
                _badgeViewContainer.backgroundColor = hasSpecialOffer ? UIColorFromRGB(color_disount_offer) : UIColorFromRGB(color_discount_save);
                _badgeLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
                _badgeLabel.attributedText = descr;
            }
            
            self.labelTitle.text = [_subscription getTitle:17.].string;
            if (hasSpecialOffer)
            {
                if (descr.length > 0)
                {
                    NSArray<NSString *> *priceComps = [discountOffer.getFormattedDescription.string componentsSeparatedByString:@"\n"];
                    if (priceComps.count == 2)
                    {
                        self.labelDescription.text = priceComps.firstObject;
                        self.tertiaryDescrLabel.text = priceComps.lastObject;
                    }
                    else
                    {
                        self.labelDescription.attributedText = [discountOffer getFormattedDescription];
                    }
                    self.tertiaryDescrLabel.hidden = self.tertiaryDescrLabel.text.length == 0;
                }
                else
                {
                    self.labelDescription.attributedText = [discountOffer getFormattedDescription];
                }
            }
            else
            {
                self.labelDescription.attributedText = _subscription.formattedPriceAttributed;
            }
            
            self.imageViewLeftIcon.image = nil;
            self.labelTitle.textColor = [UIColor colorNamed:ACColorNameButtonTextColorSecondary];
            self.labelDescription.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            [self updateSelected:selected];
            self.userInteractionEnabled = YES;
            break;
        }
        case EOAPlanTypePurchase:
        {
            self.labelTitle.text = OALocalizedString(@"complete_purchase");
            OAProductDiscount *discount = [self getDiscountOffer];
            NSString *price = discount ? discount.getFormattedDescription.string : _subscription.formattedPrice;
            self.labelDescription.text = price;

            self.layer.borderWidth = 0.;
            self.imageViewLeftIcon.image = nil;
            self.imageViewRightIcon.image = nil;
            self.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorPrimary];
            self.labelTitle.textColor = [UIColor colorNamed:ACColorNameButtonTextColorPrimary];
            self.labelDescription.textColor = [UIColor colorNamed:ACColorNameButtonTextColorPrimary];
            self.userInteractionEnabled = YES;
            break;
        }
    }
}

- (CGFloat)updateLayout:(CGFloat)y width:(CGFloat)width
{
    if ([self isDirectionRTL])
        [self rtlApplication];
    
    CGFloat newWidth = width - kPrimarySpaceMargin * 2 - [OAUtilities getLeftMargin] * 2;
    CGFloat textVerticalOffset = kSecondarySpaceMargin;
    CGFloat leftSideOffset = _type == EOAPlanTypeChoosePlan ? kSecondarySpaceMargin : kPrimarySpaceMargin;
    CGFloat rightSideOffset = _type == EOAPlanTypePurchase ? kPrimarySpaceMargin : kSecondarySpaceMargin;
    CGFloat iconMargin = kIconSize + kPrimarySpaceMargin;
    CGFloat textWidth = newWidth - leftSideOffset - rightSideOffset;
    if (_type != EOAPlanTypePurchase)
        textWidth -= iconMargin;

    CGSize titleSize = [OAUtilities calculateTextBounds:self.labelTitle.text
                                                  width:textWidth
                                                   font:self.labelTitle.font];
    self.labelTitle.frame = CGRectMake(
            leftSideOffset + (_type == EOAPlanTypeChoosePlan ? iconMargin : 0.),
            textVerticalOffset,
            textWidth,
            titleSize.height
    );
    
    BOOL hasBadge = !_badgeViewContainer.isHidden && _badgeLabel.attributedText.length > 0;
    CGSize discountSize = !hasBadge ? CGSizeZero : [OAUtilities calculateTextBounds:_badgeLabel.text width:textWidth / 2 font:_badgeLabel.font];

    CGSize descriptionSize;
    if (self.labelDescription.attributedText.length > 0)
    {
        descriptionSize = [OAUtilities calculateTextBounds:self.labelDescription.attributedText
                                                     width:textWidth - (hasBadge ? discountSize.width + 8. : 0.)];
    }
    else
    {
        descriptionSize = [OAUtilities calculateTextBounds:self.labelDescription.text
                                                     width:textWidth - (hasBadge ? discountSize.width + 8. : 0.)
                                                      font:self.labelDescription.font];
    }

    self.labelDescription.frame = CGRectMake(
            self.labelTitle.frame.origin.x + (hasBadge ? discountSize.width + 20. : 0.),
            CGRectGetMaxY(self.labelTitle.frame) + (_type == EOAPlanTypeChooseSubscription ? 8. : 0.),
            self.labelTitle.frame.size.width,
            descriptionSize.height
    );
    
    CGFloat badgeY = self.labelDescription.frame.origin.y + ((self.labelDescription.frame.size.height - (discountSize.height + 4.)) / 2);
    
    self.badgeViewContainer.frame = CGRectMake(self.labelTitle.frame.origin.x, badgeY, discountSize.width + kSecondarySpaceMargin, discountSize.height + 4.);
    
    BOOL hasTertiaryDescr = !_tertiaryDescrLabel.isHidden && _tertiaryDescrLabel.text.length > 0;
    
    CGSize tertiaryDescrSize = hasTertiaryDescr ? [OAUtilities calculateTextBounds:self.tertiaryDescrLabel.text
                                                        width:textWidth
                                                         font:self.tertiaryDescrLabel.font] : CGSizeZero;
    
    self.tertiaryDescrLabel.frame = CGRectMake(
                                               self.labelTitle.frame.origin.x,
                                               CGRectGetMaxY(hasBadge ? self.badgeViewContainer.frame : self.labelDescription.frame) + 1.,
                                               textWidth,
                                               tertiaryDescrSize.height
                                               );

    self.frame = CGRectMake(
            kPrimarySpaceMargin + [OAUtilities getLeftMargin],
            y,
            newWidth,
            self.labelDescription.frame.origin.y + self.labelDescription.frame.size.height + (hasTertiaryDescr ? self.tertiaryDescrLabel.frame.size.height + 1. : 0) + textVerticalOffset
    );

    self.imageViewLeftIcon.frame = CGRectMake(
            leftSideOffset,
            self.frame.size.height - self.frame.size.height / 2 - kIconSize / 2,
            kIconSize,
            kIconSize
    );

    self.imageViewRightIcon.frame = CGRectMake(
            newWidth - rightSideOffset - kIconSize,
            self.labelTitle.frame.origin.y + titleSize.height - titleSize.height / 2 - kIconSize / 2,
            kIconSize,
            kIconSize
    );

    return self.frame.size.height;
}

- (void)updateRightIconFrameX:(CGFloat)x
{
    CGRect frame = self.imageViewRightIcon.frame;
    frame.origin.x = x;
    self.imageViewRightIcon.frame = frame;
}

- (void)rtlApplication
{
    self.labelTitle.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.labelTitle.textAlignment = NSTextAlignmentRight;
    self.labelDescription.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.labelDescription.textAlignment = NSTextAlignmentRight;
    self.badgeLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.badgeLabel.textAlignment = NSTextAlignmentRight;
    self.tertiaryDescrLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.tertiaryDescrLabel.textAlignment = NSTextAlignmentRight;
    self.imageViewLeftIcon.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.imageViewRightIcon.transform = CGAffineTransformMakeScale(-1.0, 1.0);
}

- (void)onTapped:(UIGestureRecognizer *)recognizer
{
    if (self.delegate)
        [self.delegate onPlanTypeSelected:self.tag type:_type state:recognizer.state subscription:_subscription];
}

- (void)onLongPressed:(UIGestureRecognizer *)recognizer
{
    if (self.delegate)
        [self.delegate onPlanTypeSelected:self.tag type:_type state:recognizer.state subscription:_subscription];
}

@end
