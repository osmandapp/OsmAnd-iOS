//
//  OASimpleTableViewCell.h
//  OsmAnd
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EOATableViewCellTextIndentsStyle) {
    EOATableViewCellTextNormalIndentsStyle = 0,
    EOATableViewCellTextIncreasedTopCenterIndentStyle
};

typedef NS_ENUM(NSInteger, EOATableViewCellContentStyle) {
    EOATableViewCellContentCenterStyle = 0,
    EOATableViewCellContentTopStyle
};

@protocol OATableViewCellDelegate

- (void)onLeftEditButtonPressed:(NSInteger)tag;

@end

@interface OASimpleTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *leftEditButton;
@property (weak, nonatomic) IBOutlet UIView *topContentSpaceView;
@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UIStackView *textStackView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomContentSpaceView;

@property (weak, nonatomic) id<OATableViewCellDelegate> delegate;

- (void)updateSeparatorInset;
- (void)setCustomLeftSeparatorInset:(BOOL)isCustom;
- (CGFloat)getLeftInsetToView:(UIView *)view;

- (void)leftEditButtonVisibility:(BOOL)show;
- (void)leftIconVisibility:(BOOL)show;
- (void)titleVisibility:(BOOL)show;
- (void)descriptionVisibility:(BOOL)show;

- (void)updateMargins;
- (void)textIndentsStyle:(EOATableViewCellTextIndentsStyle)style;
- (void)anchorContent:(EOATableViewCellContentStyle)style;

@end
