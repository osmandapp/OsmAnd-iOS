//
//  OAFeatureCardView.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

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

@interface OAFeatureCardView () <OAFeatureCardRowDelegate, OAPlanTypeCardRowDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewTitleContainer;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewTitleIcon;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;

@property (weak, nonatomic) IBOutlet UILabel *labelDescription;
@property (weak, nonatomic) IBOutlet UILabel *labelProductIncluded;
@property (weak, nonatomic) IBOutlet UIView *viewHeaderSeparator;

@property (weak, nonatomic) IBOutlet UIView *viewFeatureRowsContainer;
@property (weak, nonatomic) IBOutlet UIView *viewChoosePlanButtonsContainer;
@property (weak, nonatomic) IBOutlet UIView *viewBottomSeparator;

@end

@implementation OAFeatureCardView
{
    NSInteger _selectedFeatureIndex;
    NSInteger _selectedPlanTypeIndex;
    BOOL _stateCanceled;

    OAPlanTypeCardRow *_proPlanCardRow;
    OAPlanTypeCardRow *_mapsPlanCardRow;
}

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OAFeatureCardView class]])
        {
            self = (OAFeatureCardView *) v;
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
        if ([v isKindOfClass:[OAFeatureCardView class]])
        {
            self = (OAFeatureCardView *) v;
            break;
        }
    }

    if (self)
        self.frame = frame;

    [self commonInit];
    return self;
}

- (instancetype)initWithFeature:(OAFeature *)feature
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        [self updateInfo:feature replaceFeatureRows:YES];
    }
    return self;
}

- (void)commonInit
{
    self.labelTitle.font = [UIFont scaledSystemFontOfSize:20 weight:UIFontWeightSemibold];
}

- (void)updateInfo:(OAFeature *)selectedFeature replaceFeatureRows:(BOOL)replaceFeatureRows
{
    self.imageViewTitleIcon.image = [selectedFeature getIconBig];
    self.labelTitle.text = [selectedFeature getListTitle];

    NSMutableAttributedString *attributedDescription = [[NSMutableAttributedString alloc] initWithString:[selectedFeature getDescription]];
    NSMutableParagraphStyle *descriptionParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    descriptionParagraphStyle.minimumLineHeight = 25.5;
    [attributedDescription addAttribute:NSParagraphStyleAttributeName value:descriptionParagraphStyle range:NSMakeRange(0, attributedDescription.length)];
    [attributedDescription addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] range:NSMakeRange(0, attributedDescription.length)];
    self.labelDescription.attributedText = attributedDescription;

    NSString *mapsPlus = OALocalizedString(@"product_title_plus");
    NSString *osmAndPro = OALocalizedString(@"product_title_pro");
    NSString *availablePlans = osmAndPro;
    if ([selectedFeature isAvailableInMapsPlus])
        availablePlans = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_or"), mapsPlus, osmAndPro];

    NSString *patternPlan = OALocalizedString(@"you_can_get_feature_as_part_of_pattern");
    NSString *secondaryDesc = [NSString stringWithFormat:patternPlan, [selectedFeature getListTitle], availablePlans];

    NSMutableAttributedString *productIncludedText = [[NSMutableAttributedString alloc] initWithString:secondaryDesc];
    [productIncludedText addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorSecondary] range:NSMakeRange(0, secondaryDesc.length)];
    [productIncludedText addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] range:NSMakeRange(0, secondaryDesc.length)];
    [productIncludedText addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] range:NSMakeRange(0, secondaryDesc.length)];
    [productIncludedText addAttribute:NSFontAttributeName value:[UIFont scaledSystemFontOfSize:15. weight:UIFontWeightBold] range:[secondaryDesc rangeOfString:mapsPlus]];
    [productIncludedText addAttribute:NSFontAttributeName value:[UIFont scaledSystemFontOfSize:15. weight:UIFontWeightBold] range:[secondaryDesc rangeOfString:osmAndPro]];
    NSMutableParagraphStyle *productIncludedParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    productIncludedParagraphStyle.minimumLineHeight = 21.;
    [productIncludedText addAttribute:NSParagraphStyleAttributeName value:productIncludedParagraphStyle range:NSMakeRange(0, secondaryDesc.length)];

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
                        showDivider:OAFeature.OSMAND_PRO_FEATURES.lastObject != feature
                           selected:feature == selectedFeature];
            }
        }

        for (UIView *view in self.viewChoosePlanButtonsContainer.subviews)
        {
            [view removeFromSuperview];
        }

        _proPlanCardRow = [self addPlanTypeRow:selectedFeature
                                  subscription:[OAIAPHelper sharedInstance].proMonthly];

        _mapsPlanCardRow = [self addPlanTypeRow:selectedFeature
                                   subscription:[OAIAPHelper sharedInstance].mapsAnnually];
    }

    self.labelProductIncluded.attributedText = productIncludedText;
}

- (CGFloat)updateLayout:(CGFloat)y width:(CGFloat)width
{
    if ([self isDirectionRTL])
        [self rtlApplication];
    
    CGFloat leftMargin = 20. + [OAUtilities getLeftMargin];
    CGFloat titleLeftMargin = leftMargin + kIconBigTitleSize + 16.;
    CGSize titleSize = [OAUtilities calculateTextBounds:self.labelTitle.text
                                                  width:width - (titleLeftMargin + leftMargin)
                                                   font:self.labelTitle.font];
    CGFloat titleContainerHeight = titleSize.height + 22. * 2;

    self.viewTitleContainer.frame = CGRectMake(0., 0., width, titleContainerHeight);
    self.imageViewTitleIcon.frame = CGRectMake(
            leftMargin,
            titleContainerHeight - titleContainerHeight / 2 - kIconBigTitleSize / 2,
            kIconBigTitleSize,
            kIconBigTitleSize
    );
    self.labelTitle.frame = CGRectMake(
            titleLeftMargin,
            titleContainerHeight - titleContainerHeight / 2 - titleSize.height / 2,
            titleSize.width,
            titleSize.height
    );

    CGSize descriptionSize = [OAUtilities calculateTextBounds:self.labelDescription.attributedText
                                                        width:width - leftMargin * 2];
    self.labelDescription.frame = CGRectMake(
            leftMargin,
            self.viewTitleContainer.frame.size.height + 6.,
            descriptionSize.width,
            descriptionSize.height
    );

    CGSize productIncludedSize = [OAUtilities calculateTextBounds:self.labelProductIncluded.attributedText
                                                            width:width - leftMargin * 2];
    self.labelProductIncluded.frame = CGRectMake(
            leftMargin,
            self.labelDescription.frame.origin.y + self.labelDescription.frame.size.height + 13.,
            productIncludedSize.width,
            productIncludedSize.height
    );

    self.viewHeaderSeparator.frame = CGRectMake(
            0.,
            self.labelProductIncluded.frame.origin.y + self.labelProductIncluded.frame.size.height + 13. - kSeparatorHeight,
            width,
            kSeparatorHeight
    );

    CGFloat yRow = 0.;
    for (OAFeatureCardRow *row in self.viewFeatureRowsContainer.subviews)
    {
        yRow += [row updateFrame:yRow width:width];
    }
    self.viewFeatureRowsContainer.frame = CGRectMake(
            0.,
            self.viewHeaderSeparator.frame.origin.y + kSeparatorHeight,
            width,
            yRow
    );

    yRow = 9.;
    for (OAPlanTypeCardRow *row in self.viewChoosePlanButtonsContainer.subviews)
    {
        yRow += [row updateFrame:yRow width:width] + 16.;
    }
    self.viewChoosePlanButtonsContainer.frame = CGRectMake(
            0.,
            self.viewFeatureRowsContainer.frame.origin.y + self.viewFeatureRowsContainer.frame.size.height,
            width,
            yRow
    );

    self.viewBottomSeparator.frame = CGRectMake(
            0.,
            self.viewChoosePlanButtonsContainer.frame.origin.y + self.viewChoosePlanButtonsContainer.frame.size.height + 4. - kSeparatorHeight,
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
    self.labelProductIncluded.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.labelProductIncluded.textAlignment = NSTextAlignmentRight;
    self.imageViewTitleIcon.transform = CGAffineTransformMakeScale(-1.0, 1.0);
}

- (OAFeatureCardRow *)addFeatureRow:(OAFeature *)feature showDivider:(BOOL)showDivider selected:(BOOL)selected
{
    OAFeatureCardRow *row = [[OAFeatureCardRow alloc] initWithType:EOAFeatureCardRowPlan];
    [row updateInfo:feature showDivider:showDivider selected:selected];
    row.delegate = self;
    [self.viewFeatureRowsContainer addSubview:row];
    row.tag = [self.viewFeatureRowsContainer.subviews indexOfObject:row];
    if (selected)
        _selectedFeatureIndex = row.tag;
    return row;
}

- (OAPlanTypeCardRow *)addPlanTypeRow:(OAFeature *)selectedFeature
                         subscription:(OAProduct *)subscription
{
    OAPlanTypeCardRow *row = [[OAPlanTypeCardRow alloc] initWithType:EOAPlanTypeChoosePlan];
    [row updateInfo:subscription selectedFeature:selectedFeature selected:NO];
    row.delegate = self;
    [self.viewChoosePlanButtonsContainer addSubview:row];
    row.tag = [self.viewChoosePlanButtonsContainer.subviews indexOfObject:row];
    return row;
}

#pragma mark - OAFeatureCardRowDelegate

- (void)onFeatureSelected:(NSInteger)tag state:(UIGestureRecognizerState)state
{
    if (self.viewFeatureRowsContainer.subviews.count > tag)
    {
        if (state == UIGestureRecognizerStateChanged)
        {
            _stateCanceled = YES;
            [UIView animateWithDuration:0.2 animations:^{
                OAFeatureCardRow *row = self.viewFeatureRowsContainer.subviews[tag];
                row.backgroundColor = tag == _selectedFeatureIndex ? [UIColor colorNamed:ACColorNameCellBgColorSelected] : [UIColor colorNamed:ACColorNameGroupBg];
            }                completion:nil];
        }
        else if (state == UIGestureRecognizerStateEnded)
        {
            if (_stateCanceled)
            {
                _stateCanceled = NO;
                return;
            }

            [UIView animateWithDuration:0.2 animations:^{
                OAFeatureCardRow *row = self.viewFeatureRowsContainer.subviews[_selectedFeatureIndex];
                row.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
                _selectedFeatureIndex = tag;
                row = self.viewFeatureRowsContainer.subviews[_selectedFeatureIndex];
                row.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
            }                completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 animations:^{
                    OAFeatureCardRow *row = self.viewFeatureRowsContainer.subviews[_selectedFeatureIndex];
                    row.backgroundColor = [UIColor colorNamed:ACColorNameCellBgColorSelected];
                    NSMutableArray<OAFeature *> *allFeatures = [NSMutableArray arrayWithArray:OAFeature.OSMAND_PRO_FEATURES];
                    [allFeatures removeObject:OAFeature.COMBINED_WIKI];
                    OAFeature *feature = allFeatures[tag];
                    [self updateInfo:feature replaceFeatureRows:NO];
                    [self updateLayout:self.frame.origin.y width:self.frame.size.width];
                    if (self.delegate)
                        [self.delegate onFeatureSelected:feature];

                    [_proPlanCardRow updateInfo:[OAIAPHelper sharedInstance].proMonthly
                                selectedFeature:feature
                                       selected:NO];
                    [_mapsPlanCardRow updateInfo:[OAIAPHelper sharedInstance].mapsAnnually
                                selectedFeature:feature
                                       selected:NO];
                }];
            }];
        }
        else if (state == UIGestureRecognizerStateBegan)
        {
            [UIView animateWithDuration:0.2 animations:^{
                OAFeatureCardRow *row = self.viewFeatureRowsContainer.subviews[tag];
                row.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
            }                completion:nil];
        }
    }
}

#pragma mark - OAPlanTypeCardRowDelegate

- (void)onPlanTypeSelected:(NSInteger)tag
                      type:(OAPlanTypeCardRowType)type
                     state:(UIGestureRecognizerState)state
              subscription:(OAProduct *)subscription
{
    if (self.viewChoosePlanButtonsContainer.subviews.count > tag)
    {
        if (state == UIGestureRecognizerStateChanged)
        {
            _stateCanceled = YES;
            [UIView animateWithDuration:0.2 animations:^{
                OAPlanTypeCardRow *row = self.viewChoosePlanButtonsContainer.subviews[tag];
                if (row.userInteractionEnabled)
                    row.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
            }                completion:nil];
        }
        else if (state == UIGestureRecognizerStateEnded)
        {
            if (_stateCanceled)
            {
                _stateCanceled = NO;
                return;
            }

            [UIView animateWithDuration:0.2 animations:^{
                OAPlanTypeCardRow *row = self.viewChoosePlanButtonsContainer.subviews[_selectedPlanTypeIndex];
                if (type == EOAPlanTypeChooseSubscription)
                    [row updateSelected:tag == _selectedPlanTypeIndex];
                _selectedPlanTypeIndex = tag;
                row = self.viewChoosePlanButtonsContainer.subviews[_selectedPlanTypeIndex];
                if (row.userInteractionEnabled)
                    row.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
            }                completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 animations:^{
                    OAPlanTypeCardRow *row = self.viewChoosePlanButtonsContainer.subviews[_selectedPlanTypeIndex];
                    if (row.userInteractionEnabled)
                        row.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
                    if (self.delegate)
                        [self.delegate onPlanTypeSelected:subscription];
                }];
            }];
        }
        else if (state == UIGestureRecognizerStateBegan)
        {
            [UIView animateWithDuration:0.2 animations:^{
                OAPlanTypeCardRow *row = self.viewChoosePlanButtonsContainer.subviews[tag];
                if (row.userInteractionEnabled)
                    row.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
            }                completion:nil];
        }
    }
}

@end
