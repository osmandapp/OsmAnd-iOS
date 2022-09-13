//
//  OAMultiIconsDescCustomCell.m
//  OsmAnd Maps
//
//  Created by Skalii on 08.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACustomBasicTableCell.h"

@interface OACustomBasicTableCell ()

@property (weak, nonatomic) IBOutlet UIStackView *textCustomMarginTopStackView;
@property (weak, nonatomic) IBOutlet UIView *topContentSpaceView;
@property (weak, nonatomic) IBOutlet UIStackView *contentInsideStackView;
@property (weak, nonatomic) IBOutlet UIStackView *textStackView;
@property (weak, nonatomic) IBOutlet UIView *bottomContentSpaceView;
@property (weak, nonatomic) IBOutlet UIStackView *textCustomMarginBottomStackView;
@property (weak, nonatomic) IBOutlet UIStackView *valueStackView;

@end

@implementation OACustomBasicTableCell

- (void)leftIconVisibility:(BOOL)show
{
    self.leftIconView.hidden = !show;
}

- (void)descriptionVisibility:(BOOL)show
{
    self.descriptionLabel.hidden = !show;
    self.topContentSpaceView.hidden = !show;
    self.bottomContentSpaceView.hidden = !show;
}

- (void)valueVisibility:(BOOL)show
{
    self.valueStackView.hidden = !show;
}

- (void)rightIconVisibility:(BOOL)show
{
    self.rightIconView.hidden = !show;
}

- (void)switchVisibility:(BOOL)show
{
    self.switchView.hidden = !show;
}

- (void)textIndentsStyle:(EOACustomCellTextIndentsStyle)style
{
    if (style == EOACustomCellTextNormalIndentsStyle)
    {
        self.textCustomMarginTopStackView.spacing = 5.;
        self.textStackView.spacing = 2.;
        self.textCustomMarginBottomStackView.spacing = 5.;
    }
    else if (style == EOACustomCellTextIncreasedTopCenterIndentStyle)
    {
        self.textCustomMarginTopStackView.spacing = 9.;
        self.textStackView.spacing = 6.;
        self.textCustomMarginBottomStackView.spacing = 5.;
    }
}

- (void)anchorContent:(EOACustomCellContentStyle)style
{
    if (style == EOACustomCellContentCenterStyle)
    {
        self.contentInsideStackView.alignment = UIStackViewAlignmentCenter;
    }
    else if (style == EOACustomCellContentTopStyle)
    {
        self.contentInsideStackView.alignment = UIStackViewAlignmentTop;
    }
}

@end
