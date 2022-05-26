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

#define kIconBigTitleSize 48.

@interface OASubscriptionCardView () <OAFeatureCardRowDelegate, OAPlanTypeCardRowDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewTitleContainer;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewTitleIcon;

@property (weak, nonatomic) IBOutlet UIView *viewFeatureRowsContainer;
@property (weak, nonatomic) IBOutlet UIView *viewChooseSubscriptionButtonsContainer;
@property (weak, nonatomic) IBOutlet UILabel *labelPurchaseDescription;

@property (weak, nonatomic) IBOutlet UIView *viewBottomSeparator;

@end

@implementation OASubscriptionCardView
{
    NSInteger _selectedSubscriptionIndex;
    NSInteger _buttonLearnMoreIndex;
    BOOL _buttonPressCanceled;

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

- (instancetype)initWithSubscription:(OASubscription *)subscription
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
    self.labelTitle.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    self.labelDescription.font = [UIFont systemFontOfSize:17];
    self.labelDescription.textColor = UIColorFromRGB(color_text_footer);
    [self.labelPurchaseDescription setText:OALocalizedString(@"subscription_cancel_description")];
    self.viewChooseSubscriptionButtonsContainer.layer.borderWidth = 1.;
    self.viewChooseSubscriptionButtonsContainer.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
    self.viewChooseSubscriptionButtonsContainer.layer.cornerRadius = 9.;
}

- (BOOL)isProPlan:(OASubscription *)subscription
{
    return [subscription isEqual:[OAIAPHelper sharedInstance].proMonthly] || [subscription isEqual:[OAIAPHelper sharedInstance].proAnnually];
}

- (void)updateInfo:(OASubscription *)subscription replaceFeatureRows:(BOOL)replaceFeatureRows
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
        learnMoreButton.labelTitle.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
        learnMoreButton.delegate = self;
        learnMoreButton.tag = [self.viewFeatureRowsContainer.subviews indexOfObject:learnMoreButton];
        _buttonLearnMoreIndex = learnMoreButton.tag;

        for (UIView *view in self.viewChooseSubscriptionButtonsContainer.subviews)
        {
            [view removeFromSuperview];
        }

        OASubscription *selectedSubscription = [self isProPlan:subscription]
                ? [OAIAPHelper sharedInstance].proMonthly
                : [OAIAPHelper sharedInstance].mapsAnnually;
        [self addPlanTypeRow:EOAPlanTypeChooseSubscription
                                            subscription:selectedSubscription
                                                selected:YES
                                               container:self.viewChooseSubscriptionButtonsContainer];

        [self addPlanTypeRow:EOAPlanTypeChooseSubscription
                                                subscription:[self isProPlan:subscription]
                                                        ? [OAIAPHelper sharedInstance].proAnnually
                                                        : [OAIAPHelper sharedInstance].mapsFull
                                                     selected:NO
                                                    container:self.viewChooseSubscriptionButtonsContainer];

        _completePurchasePlanCardRow = [self addPlanTypeRow:EOAPlanTypePurchase
                                               subscription:selectedSubscription
                                                   selected:NO
                                                  container:self];
    }
}

- (CGFloat)updateLayout:(CGFloat)y
{
    CGFloat width = DeviceScreenWidth;
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
            9.,
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
        yRow += [row updateFrame:yRow];
    }
    self.viewFeatureRowsContainer.frame = CGRectMake(
            0.,
            self.self.viewTitleContainer.frame.origin.y + self.viewTitleContainer.frame.size.height,
            width,
            yRow
    );

    yRow = 0.;
    for (OAPlanTypeCardRow *row in self.viewChooseSubscriptionButtonsContainer.subviews)
    {
        yRow += [row updateFrame:yRow];
        CGRect frame = row.frame;
        frame.origin.x = 0.;
        frame.size.width = width - leftMargin * 2;
        row.frame = frame;
    }
    self.viewChooseSubscriptionButtonsContainer.frame = CGRectMake(
            leftMargin,
            self.viewFeatureRowsContainer.frame.origin.y + self.viewFeatureRowsContainer.frame.size.height + 20.,
            width - leftMargin * 2,
            yRow
    );

    yRow = self.viewChooseSubscriptionButtonsContainer.frame.origin.y + self.viewChooseSubscriptionButtonsContainer.frame.size.height + 20.;
    CGFloat purchaseButtonHeight = [_completePurchasePlanCardRow updateFrame:yRow];
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
                dividerWidth:DeviceScreenWidth
                        icon:icon];
    [self.viewFeatureRowsContainer addSubview:row];
    return row;
}

- (OAPlanTypeCardRow *)addPlanTypeRow:(OAPlanTypeCardRowType)type
                         subscription:(OASubscription *)subscription
                             selected:(BOOL)selected
                            container:(UIView *)container
{
    OAPlanTypeCardRow *row = [[OAPlanTypeCardRow alloc] initWithType:type];
    [row updateInfo:subscription selectedFeature:nil selected:selected];
    row.delegate = self;
    [container addSubview:row];
    row.tag = [container.subviews indexOfObject:row];
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
              subscription:(OASubscription *)subscription
{
    BOOL isPurchaseButton = _completePurchasePlanCardRow.tag == tag;
    if (self.viewChooseSubscriptionButtonsContainer.subviews.count > tag || isPurchaseButton)
    {
        if (state == UIGestureRecognizerStateChanged)
        {
            _buttonPressCanceled = YES;
            [UIView animateWithDuration:0.2 animations:^{
                OAPlanTypeCardRow *row = isPurchaseButton ? _completePurchasePlanCardRow : self.viewChooseSubscriptionButtonsContainer.subviews[tag];
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
                OAPlanTypeCardRow *row = isPurchaseButton ? _completePurchasePlanCardRow : self.viewChooseSubscriptionButtonsContainer.subviews[_selectedSubscriptionIndex];
                if (type == EOAPlanTypeChooseSubscription)
                {
                    [row updateSelected:tag == _selectedSubscriptionIndex];
                    _selectedSubscriptionIndex = tag;
                }
                row = isPurchaseButton ? _completePurchasePlanCardRow : self.viewChooseSubscriptionButtonsContainer.subviews[_selectedSubscriptionIndex];
                if (row.userInteractionEnabled)
                    row.backgroundColor = UIColorFromARGB(color_primary_purple_50);
            }                completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 animations:^{
                    OAPlanTypeCardRow *row = isPurchaseButton ? _completePurchasePlanCardRow : self.viewChooseSubscriptionButtonsContainer.subviews[_selectedSubscriptionIndex];
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
                OAPlanTypeCardRow *row = isPurchaseButton ? _completePurchasePlanCardRow : self.viewChooseSubscriptionButtonsContainer.subviews[tag];
                if (row.userInteractionEnabled)
                    row.backgroundColor = UIColorFromARGB(color_primary_purple_50);
            }                completion:nil];
        }
    }
}

@end
