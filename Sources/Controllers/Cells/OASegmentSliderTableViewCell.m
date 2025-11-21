//
//  OASegmentSliderTableViewCell.m
//  OsmAnd
//
//  Created by igor on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASegmentSliderTableViewCell.h"
#import "GeneratedAssetSymbols.h"

@interface OASegmentSliderTableViewCell () <OASegmentedSliderDelegate>

@property (weak, nonatomic) IBOutlet UIButton *plusButton;
@property (weak, nonatomic) IBOutlet UIButton *minusButton;

@end

@implementation OASegmentSliderTableViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self.plusButton setImage:[UIImage templateImageNamed:@"ic_custom_map_zoom_in"] forState:UIControlStateNormal];
    [self.plusButton addTarget:self action:@selector(plusTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.plusButton setTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
    [self.minusButton setImage:[UIImage templateImageNamed:@"ic_custom_map_zoom_out"] forState:UIControlStateNormal];
    [self.minusButton addTarget:self action:@selector(minusTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.minusButton setTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
    [self showButtons:NO];
    self.sliderView.delegate = self;

    if ([self isDirectionRTL])
    {
        self.topRightLabel.textAlignment = NSTextAlignmentLeft;
        self.bottomRightLabel.textAlignment = NSTextAlignmentLeft;
    }
}

- (void)setupButtonsEnabling
{
    BOOL isPlusButtonEnabled = self.sliderView.selectedMark < [self.sliderView getMarksCount] - 1;
    BOOL isMinusButtonEnabled = self.sliderView.selectedMark > 0;
    [self.plusButton setTintColor:[UIColor colorNamed:isPlusButtonEnabled ? ACColorNameIconColorActive : ACColorNameIconColorDisabled]];
    [self.plusButton setEnabled:isPlusButtonEnabled];
    [self.minusButton setTintColor:[UIColor colorNamed:isMinusButtonEnabled ? ACColorNameIconColorActive : ACColorNameIconColorDisabled]];
    [self.minusButton setEnabled:isMinusButtonEnabled];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)showAllLabels:(BOOL)show
{
    [self showLabels:show topRight:show bottomLeft:show bottomRight:show];
}

- (void)showLabels:(BOOL)topLeft topRight:(BOOL)topRight bottomLeft:(BOOL)bottomLeft bottomRight:(BOOL)bottomRight;
{
    self.topLeftLabel.hidden = !topLeft;
    self.topRightLabel.hidden = !topRight;
    self.bottomLeftLabel.hidden = !bottomLeft;
    self.bottomRightLabel.hidden = !bottomRight;

    UIFont *bottomLabelsFont = [UIFont scaledSystemFontOfSize:topLeft || topRight ? 15. : 17.];
    self.bottomLeftLabel.font = bottomLabelsFont;
    self.bottomRightLabel.font = bottomLabelsFont;
}

- (void)showButtons:(BOOL)show
{
    self.plusButton.hidden = !show;
    self.minusButton.hidden = !show;
}

- (void)updateConstraints
{
    BOOL hasLeftTopLabel = !self.topLeftLabel.hidden;
    BOOL hasRightTopLabel = !self.topRightLabel.hidden;
    BOOL hasTopLabels = hasLeftTopLabel || hasRightTopLabel;

    BOOL hasLeftBottomLabel = !self.bottomLeftLabel.hidden;
    BOOL hasRightBottomLabel = !self.bottomRightLabel.hidden;
    BOOL hasBottomLabels = hasLeftBottomLabel || hasRightBottomLabel;

    self.sliderLabelsTopConstraint.active = hasTopLabels;
    self.sliderNoLabelsTopConstraint.active = !hasTopLabels;

    self.sliderLabelsBottomConstraint.constant = hasTopLabels ? 7. : 13.;
    self.sliderLabelsBottomConstraint.active = hasBottomLabels;
    self.sliderNoLabelsBottomConstraint.active = !hasBottomLabels;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasLeftTopLabel = !self.topLeftLabel.hidden;
        BOOL hasRightTopLabel = !self.topRightLabel.hidden;
        BOOL hasTopLabels = hasLeftTopLabel || hasRightTopLabel;

        BOOL hasLeftBottomLabel = !self.bottomLeftLabel.hidden;
        BOOL hasRightBottomLabel = !self.bottomRightLabel.hidden;
        BOOL hasBottomLabels = hasLeftBottomLabel || hasRightBottomLabel;

        res = res || self.sliderLabelsTopConstraint.active != hasTopLabels;
        res = res || self.sliderNoLabelsTopConstraint.active != !hasTopLabels;

        res = res || self.sliderLabelsBottomConstraint.constant != (hasTopLabels ? 7. : 13.);
        res = res || self.sliderLabelsBottomConstraint.active != hasBottomLabels;
        res = res || self.sliderNoLabelsBottomConstraint.active != !hasBottomLabels;
    }
    return res;
}

- (void)plusTapped
{
    if (self.sliderView.selectedMark < [self.sliderView getMarksCount] - 1)
    {
        [self.sliderView setSelectedMark:self.sliderView.selectedMark + 1];
        [self.delegate onPlusTapped:self.sliderView.selectedMark];
    }
}

- (void)minusTapped
{
    if (self.sliderView.selectedMark > 0)
    {
        [self.sliderView setSelectedMark:self.sliderView.selectedMark - 1];
        [self.delegate onMinusTapped:self.sliderView.selectedMark];
    }
}

- (void)onSliderFinishEditing
{
    [self setupButtonsEnabling];
}

@end
