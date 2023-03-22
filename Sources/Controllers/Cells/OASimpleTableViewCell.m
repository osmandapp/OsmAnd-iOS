//
//  OASimpleTableViewCell.m
//  OsmAnd Maps
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASimpleTableViewCell.h"
#import "OASizes.h"
#import "UITableViewCell+getTableView.h"

@interface OASimpleTableViewCell ()

@property (weak, nonatomic) IBOutlet UIStackView *contentOutsideStackViewVertical;
@property (weak, nonatomic) IBOutlet UIStackView *textCustomMarginTopStackView;
@property (weak, nonatomic) IBOutlet UIStackView *contentInsideStackView;
@property (weak, nonatomic) IBOutlet UIStackView *textCustomMarginBottomStackView;

@end

@implementation OASimpleTableViewCell
{
    BOOL _isCustomLeftSeparatorInset;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!_isCustomLeftSeparatorInset)
        [self updateSeparatorInset];
}

- (void)setCustomLeftSeparatorInset:(BOOL)isCustom
{
    _isCustomLeftSeparatorInset = isCustom;
}

- (void)updateSeparatorInset
{
    CGRect titleFrame = [self.titleLabel convertRect:self.titleLabel.bounds toView:self];
    CGFloat leftInset = [self isDirectionRTL] ? ([self getTableView].frame.size.width - (titleFrame.origin.x + titleFrame.size.width)) : titleFrame.origin.x;
    self.separatorInset = UIEdgeInsetsMake(0., leftInset, 0., 0.);
}

- (void)leftEditButtonVisibility:(BOOL)show
{
    self.leftEditButton.hidden = !show;
    [self updateMargins];
}

- (void)leftIconVisibility:(BOOL)show
{
    self.leftIconView.hidden = !show;
    [self updateMargins];
}

- (void)titleVisibility:(BOOL)show
{
    self.titleLabel.hidden = !show;
    if (!show && self.descriptionLabel.hidden)
        self.textStackView.hidden = YES;

    [self updateMargins];
}

- (void)descriptionVisibility:(BOOL)show
{
    self.descriptionLabel.hidden = !show;
    if (!show && self.titleLabel.hidden)
        self.textStackView.hidden = YES;

    [self updateMargins];
}

- (void)updateMargins
{
    BOOL hidden = (self.descriptionLabel.hidden || self.titleLabel.hidden) && (!self.leftEditButton.hidden || !self.leftIconView.hidden || [self checkSubviewsToUpdateMargins]);
    self.topContentSpaceView.hidden = hidden;
    self.bottomContentSpaceView.hidden = hidden;
    self.contentOutsideStackViewVertical.spacing = hidden ? 3 : 4;
}

- (BOOL)checkSubviewsToUpdateMargins
{
    return !self.leftIconView.hidden;
}

- (void)textIndentsStyle:(EOATableViewCellTextIndentsStyle)style
{
    self.textCustomMarginTopStackView.spacing = style == EOATableViewCellTextIncreasedTopCenterIndentStyle ? 9. : 5.;
    self.textStackView.spacing = style == EOATableViewCellTextNormalIndentsStyle ? 2. : 6.;
    self.textCustomMarginBottomStackView.spacing = 5.;
}

- (void)anchorContent:(EOATableViewCellContentStyle)style
{
    if (style == EOATableViewCellContentCenterStyle)
    {
        self.contentInsideStackView.alignment = UIStackViewAlignmentCenter;
    }
    else if (style == EOATableViewCellContentTopStyle)
    {
        self.contentInsideStackView.alignment = UIStackViewAlignmentTop;
    }
}

@end
