//
//  OASubscriptionCardView.mm
//  OsmAnd
//
//  Created by Skalii on 24.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OASubscriptionCardView.h"
#import "OAFeatureCardView.h"
#import "OAFeatureCardRow.h"
#import "OAPlanTypeCardRow.h"
#import "OAChoosePlanHelper.h"
#import "OAIAPHelper.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kIconBigTitleSize 48.

@interface OASubscriptionCardView () <OAFeatureCardRowDelegate, OAPlanTypeCardRowDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewTitleContainer;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewTitleIcon;

@property (weak, nonatomic) IBOutlet UIView *viewFeatureRowsContainer;
@property (weak, nonatomic) IBOutlet UIView *viewChooseSubscriptionButtonsBorder;
@property (weak, nonatomic) IBOutlet UILabel *labelPurchaseDescription;

@property (weak, nonatomic) IBOutlet UIView *viewBottomSeparator;

@end

@implementation OASubscriptionCardView
{
    NSInteger _selectedSubscriptionIndex;
    NSInteger _buttonLearnMoreIndex;
    BOOL _buttonPressCanceled;

    OAPlanTypeCardRow *_firstPlanCardRow;
    OAPlanTypeCardRow *_secondPlanCardRow;
    OAPlanTypeCardRow *_completePurchasePlanCardRow;
}

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OASubscriptionCardView class]])
        {
            self = (OASubscriptionCardView *) v;
            break;
        }
    }

    if (self)
        self.frame = CGRectMake(0, 0, 200, 100);

    [self commonInit];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OASubscriptionCardView class]])
        {
            self = (OASubscriptionCardView *) v;
            break;
        }
    }

    if (self)
        self.frame = frame;

    [self commonInit];
    return self;
}

- (instancetype)initWithSubscription:(OAProduct *)subscription
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        [self updateInfo:subscription replaceFeatureRows:YES];
    }
    return self;
}

- (void)commonInit
{
    self.labelTitle.font = [UIFont scaledSystemFontOfSize:34 weight:UIFontWeightBold];
    self.labelDescription.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.labelDescription.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    [self.labelPurchaseDescription setText:OALocalizedString(@"subscription_cancel_description")];
    self.viewChooseSubscriptionButtonsBorder.layer.borderWidth = 1.;
    self.viewChooseSubscriptionButtonsBorder.layer.borderColor = [UIColor colorNamed:ACColorNameButtonBgColorSecondary].CGColor;
    self.viewChooseSubscriptionButtonsBorder.layer.cornerRadius = 9.;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        self.viewChooseSubscriptionButtonsBorder.layer.borderColor = [UIColor colorNamed:ACColorNameButtonBgColorSecondary].CGColor;
}

- (BOOL)isProPlan:(OAProduct *)subscription
{
    return [subscription isKindOfClass:OASubscription.class] && [OAIAPHelper isOsmAndProSubscription:(OASubscription *) subscription];
}

- (void)updateInfo:(OAProduct *)subscription replaceFeatureRows:(BOOL)replaceFeatureRows
{
    NSString *iconName = subscription.productIconName;
    UIImage *icon = [UIImage imageNamed:[iconName stringByAppendingString:@"_big"]];
    if (!icon)
        icon = [UIImage imageNamed:iconName];
    self.imageViewTitleIcon.image = icon;
    self.labelTitle.text = subscription.localizedTitle;
    self.labelDescription.text = subscription.localizedDescription;

    if (replaceFeatureRows)
    {
        for (UIView *view in self.viewFeatureRowsContainer.subviews)
        {
            [view removeFromSuperview];
        }

        for (OAFeature *feature in OAFeature.OSMAND_PRO_FEATURES)
        {
            if (feature != OAFeature.COMBINED_WIKI)
            {
                [self addFeatureRow:feature
                        showDivider:NO
                           selected:[feature isAvailableInMapsPlus] || [self isProPlan:subscription]];
            }
        }
        OAFeatureCardRow *learnMoreButton = [self addSimpleRow:OALocalizedString(@"shared_string_learn_more")
                                                   showDivider:YES
                                                          icon:@"ic_custom_arrow_down_short"];
        learnMoreButton.labelTitle.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
        learnMoreButton.delegate = self;
        learnMoreButton.tag = [self.viewFeatureRowsContainer.subviews indexOfObject:learnMoreButton];
        _buttonLearnMoreIndex = learnMoreButton.tag;

        OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
        OAProduct *selectedSubscription = [self isProPlan:subscription] ? iapHelper.proMonthly : iapHelper.mapsAnnually;

        _firstPlanCardRow = [self addPlanTypeRow:EOAPlanTypeChooseSubscription
                                    subscription:selectedSubscription
                                        selected:YES];

        _secondPlanCardRow = [self addPlanTypeRow:EOAPlanTypeChooseSubscription
                                     subscription:[self isProPlan:subscription] ? iapHelper.proAnnually : iapHelper.mapsFull
                                         selected:NO];

        _completePurchasePlanCardRow = [self addPlanTypeRow:EOAPlanTypePurchase
                                               subscription:selectedSubscription
                                                   selected:NO];
    }
}

- (CGFloat)updateLayout:(CGFloat)y width:(CGFloat)width
{
    if ([self isDirectionRTL])
        [self rtlApplication];
    
    CGFloat leftMargin = 20. + [OAUtilities getLeftMargin];
    CGFloat titleRightMargin = leftMargin + kIconBigTitleSize + 16.;
    CGSize titleSize = [OAUtilities calculateTextBounds:self.labelTitle.text
                                                  width:width - (titleRightMargin + leftMargin)
                                                   font:self.labelTitle.font];
    CGFloat titleContainerHeight = titleSize.height + 20. * 2;

    self.viewTitleContainer.frame = CGRectMake(0., 0., width, titleContainerHeight);
    self.imageViewTitleIcon.frame = CGRectMake(
            width - leftMargin - kIconBigTitleSize,
            titleContainerHeight - titleContainerHeight / 2 - kIconBigTitleSize / 2,
            kIconBigTitleSize,
            kIconBigTitleSize
    );
    self.labelTitle.frame = CGRectMake(
            leftMargin,
            self.viewTitleContainer.frame.origin.y,
            titleSize.width,
            titleSize.height
    );

    CGSize descriptionSize = [OAUtilities calculateTextBounds:self.labelDescription.text
                                                        width:width - (titleRightMargin + leftMargin)
                                                         font:self.labelDescription.font];
    self.labelDescription.frame = CGRectMake(
            leftMargin,
            self.labelTitle.frame.origin.y + self.labelTitle.frame.size.height,
            descriptionSize.width,
            descriptionSize.height
    );

    CGFloat yRow = 0.;
    for (OAFeatureCardRow *row in self.viewFeatureRowsContainer.subviews)
    {
        yRow += [row updateFrame:yRow width:width];
    }
    self.viewFeatureRowsContainer.frame = CGRectMake(
            0.,
            self.self.viewTitleContainer.frame.origin.y + self.viewTitleContainer.frame.size.height,
            width,
            yRow
    );

    [_firstPlanCardRow updateFrame:self.viewFeatureRowsContainer.frame.origin.y + self.viewFeatureRowsContainer.frame.size.height + 20. width:width];
    CGRect firstPlanFrame = _firstPlanCardRow.frame;
    firstPlanFrame.origin.x = leftMargin;
    firstPlanFrame.size.width = width - leftMargin * 2;
    _firstPlanCardRow.frame = firstPlanFrame;
    [_firstPlanCardRow updateRightIconFrameX:_firstPlanCardRow.frame.size.width - kSecondarySpaceMargin - kIconSize];

    [_secondPlanCardRow updateFrame:_firstPlanCardRow.frame.origin.y + _firstPlanCardRow.frame.size.height width:width];
    CGRect secondPlanFrame = _secondPlanCardRow.frame;
    secondPlanFrame.origin.x = leftMargin;
    secondPlanFrame.size.width = width - leftMargin * 2;
    _secondPlanCardRow.frame = secondPlanFrame;
    [_secondPlanCardRow updateRightIconFrameX:_secondPlanCardRow.frame.size.width - kSecondarySpaceMargin - kIconSize];

    self.viewChooseSubscriptionButtonsBorder.frame = CGRectMake(
            leftMargin,
            _firstPlanCardRow.frame.origin.y,
            width - leftMargin * 2,
            _firstPlanCardRow.frame.size.height + _secondPlanCardRow.frame.size.height
    );

    yRow = self.viewChooseSubscriptionButtonsBorder.frame.origin.y + self.viewChooseSubscriptionButtonsBorder.frame.size.height + 20.;
    CGFloat purchaseButtonHeight = [_completePurchasePlanCardRow updateFrame:yRow width:width];
    _completePurchasePlanCardRow.frame = CGRectMake(
            leftMargin,
            yRow,
            width - leftMargin * 2,
            purchaseButtonHeight
    );

    CGSize purchaseDescriptionSize = [OAUtilities calculateTextBounds:self.labelPurchaseDescription.text
                                                                width:width - leftMargin * 2
                                                                 font:self.labelPurchaseDescription.font];
    self.labelPurchaseDescription.frame = CGRectMake(
            leftMargin,
            _completePurchasePlanCardRow.frame.origin.y + _completePurchasePlanCardRow.frame.size.height + 13.,
            width - leftMargin * 2,
            purchaseDescriptionSize.height
    );

    self.viewBottomSeparator.frame = CGRectMake(
            0.,
            self.labelPurchaseDescription.frame.origin.y + self.labelPurchaseDescription.frame.size.height + 13. - kSeparatorHeight,
            width,
            kSeparatorHeight
    );

    self.frame = CGRectMake(0., y, width, self.viewBottomSeparator.frame.origin.y + kSeparatorHeight);
    return self.frame.size.height;
}

- (void)rtlApplication
{
    self.labelTitle.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.labelTitle.textAlignment = NSTextAlignmentRight;
    self.labelDescription.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.labelDescription.textAlignment = NSTextAlignmentRight;
    self.labelPurchaseDescription.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.labelPurchaseDescription.textAlignment = NSTextAlignmentRight;
}

- (OAFeatureCardRow *)addFeatureRow:(OAFeature *)feature showDivider:(BOOL)showDivider selected:(BOOL)selected
{
    OAFeatureCardRow *row = [[OAFeatureCardRow alloc] initWithType:EOAFeatureCardRowSubscription];
    [row updateInfo:feature showDivider:showDivider selected:selected];
    [self.viewFeatureRowsContainer addSubview:row];
    return row;
}

- (OAFeatureCardRow *)addSimpleRow:(NSString *)title showDivider:(BOOL)showDivider icon:(NSString *)icon
{
    OAFeatureCardRow *row = [[OAFeatureCardRow alloc] initWithType:EOAFeatureCardRowSimple];
    [row updateSimpleRowInfo:title
                 showDivider:showDivider
           dividerLeftMargin:0.
                        icon:icon];
    [self.viewFeatureRowsContainer addSubview:row];
    return row;
}

- (OAPlanTypeCardRow *)addPlanTypeRow:(OAPlanTypeCardRowType)type
                         subscription:(OAProduct *)subscription
                             selected:(BOOL)selected
{
    OAPlanTypeCardRow *row = [[OAPlanTypeCardRow alloc] initWithType:type];
    [row updateInfo:subscription selectedFeature:nil selected:selected];
    row.delegate = self;
    [self addSubview:row];
    row.tag = [self.subviews indexOfObject:row];
    if (selected)
        _selectedSubscriptionIndex = row.tag;
    return row;
}

#pragma mark - OAFeatureCardRowDelegate

- (void)onFeatureSelected:(NSInteger)tag state:(UIGestureRecognizerState)state
{
    if (tag == _buttonLearnMoreIndex && self.delegate)
        [self.delegate onLearnMoreButtonSelected];
}

#pragma mark - OAPlanTypeCardRowDelegate

- (void)onPlanTypeSelected:(NSInteger)tag
                      type:(OAPlanTypeCardRowType)type
                     state:(UIGestureRecognizerState)state
              subscription:(OAProduct *)subscription
{
    BOOL isPurchaseButton = _completePurchasePlanCardRow.tag == tag;
    if (self.subviews.count > tag || isPurchaseButton)
    {
        if (state == UIGestureRecognizerStateChanged)
        {
            _buttonPressCanceled = YES;
            [UIView animateWithDuration:0.2 animations:^{
                OAPlanTypeCardRow *row = isPurchaseButton ? _completePurchasePlanCardRow : self.subviews[tag];
                if (type == EOAPlanTypeChooseSubscription)
                    [row updateSelected:tag == _selectedSubscriptionIndex];
                else if (type == EOAPlanTypePurchase)
                    row.backgroundColor = UIColorFromRGB(color_primary_purple);
            }                completion:nil];
        }
        else if (state == UIGestureRecognizerStateEnded)
        {
            if (_buttonPressCanceled)
            {
                _buttonPressCanceled = NO;
                return;
            }

            [UIView animateWithDuration:0.2 animations:^{
                OAPlanTypeCardRow *row = isPurchaseButton ? _completePurchasePlanCardRow : self.subviews[_selectedSubscriptionIndex];
                if (type == EOAPlanTypeChooseSubscription)
                {
                    [row updateSelected:tag == _selectedSubscriptionIndex];
                    _selectedSubscriptionIndex = tag;
                }
                row = isPurchaseButton ? _completePurchasePlanCardRow : self.subviews[_selectedSubscriptionIndex];
                if (row.userInteractionEnabled)
                    row.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
            }                completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 animations:^{
                    OAPlanTypeCardRow *row = isPurchaseButton ? _completePurchasePlanCardRow : self.subviews[_selectedSubscriptionIndex];
                    if (type == EOAPlanTypeChooseSubscription)
                    {
                        [row updateSelected:tag == _selectedSubscriptionIndex];
                        [_completePurchasePlanCardRow updateInfo:subscription
                                                 selectedFeature:nil
                                                        selected:NO];
                    }
                    else if (type == EOAPlanTypePurchase)
                    {
                        row.backgroundColor = UIColorFromRGB(color_primary_purple);
                        if (self.delegate)
                            [self.delegate onPlanTypeSelected:subscription];
                    }
                }];
            }];
        }
        else if (state == UIGestureRecognizerStateBegan)
        {
            [UIView animateWithDuration:0.2 animations:^{
                OAPlanTypeCardRow *row = isPurchaseButton ? _completePurchasePlanCardRow : self.subviews[tag];
                if (row.userInteractionEnabled)
                    row.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
            }                completion:nil];
        }
    }
}

@end
