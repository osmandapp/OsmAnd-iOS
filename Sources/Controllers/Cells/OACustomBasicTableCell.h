//
//  OAMultiIconsDescCustomCell.h
//  OsmAnd
//
//  Created by SKalii on 08.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EOACustomCellTextIndentsStyle) {
    EOACustomCellTextNormalIndentsStyle = 0,
    EOACustomCellTextIncreasedTopCenterIndentStyle
};

typedef NS_ENUM(NSInteger, EOACustomCellContentStyle) {
    EOACustomCellContentCenterStyle = 0,
    EOACustomCellContentTopStyle
};

@interface OACustomBasicTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UIStackView *rightContentStackView;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UIImageView *rightIconView;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;

- (void)leftIconVisibility:(BOOL)show;
- (void)descriptionVisibility:(BOOL)show;
- (void)valueVisibility:(BOOL)show;
- (void)rightIconVisibility:(BOOL)show;
- (void)switchVisibility:(BOOL)show;

- (void)textIndentsStyle:(EOACustomCellTextIndentsStyle)style;
- (void)anchorContent:(EOACustomCellContentStyle)style;

@end
