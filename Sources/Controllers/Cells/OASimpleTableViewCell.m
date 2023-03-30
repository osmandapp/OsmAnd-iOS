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

@interface OASimpleTableViewCell () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIStackView *contentOutsideStackViewVertical;
@property (weak, nonatomic) IBOutlet UIStackView *textCustomMarginTopStackView;
@property (weak, nonatomic) IBOutlet UIStackView *contentInsideStackView;
@property (weak, nonatomic) IBOutlet UIStackView *textCustomMarginBottomStackView;

@end

@implementation OASimpleTableViewCell
{
    BOOL _isCustomLeftSeparatorInset;
    UITapGestureRecognizer *_tapRecognizer;
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
    self.separatorInset = UIEdgeInsetsMake(0., [self getLeftInsetToView:self.titleLabel], 0., 0.);
}

- (CGFloat)getLeftInsetToView:(UIView *)view
{
    CGRect viewFrame = [view convertRect:view.bounds toView:self];
    return [self isDirectionRTL] ? ([self getTableView].frame.size.width - (viewFrame.origin.x + viewFrame.size.width)) : viewFrame.origin.x;
}

- (void)leftEditButtonVisibility:(BOOL)show
{
    self.leftEditButton.hidden = !show;
    [self updateMargins];

    if (show)
    {
        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onLeftEditButtonPressed:)];
        [self addGestureRecognizer:_tapRecognizer];
        _tapRecognizer.delegate = self;
    }
    else if (_tapRecognizer)
    {
        [self removeGestureRecognizer:_tapRecognizer];
        _tapRecognizer = nil;
    }
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

#pragma mark - Selectors

- (void)onLeftEditButtonPressed:(UIGestureRecognizer *)recognizer
{
    if (self.delegate && recognizer.state == UIGestureRecognizerStateEnded)
        [self.delegate onLeftEditButtonPressed:self.leftEditButton.tag];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.leftEditButton.hidden || !self.leftEditButton.enabled)
        return NO;

    CGFloat leftInset = [self getLeftInsetToView:self.leftIconView.hidden ? self.titleLabel : self.leftIconView];
    CGFloat pressedXLocation = [gestureRecognizer locationInView:self].x;
    if ([self isDirectionRTL])
        return [self getTableView].frame.size.width - pressedXLocation <= leftInset;
    else
        return pressedXLocation <= leftInset;
}

@end
