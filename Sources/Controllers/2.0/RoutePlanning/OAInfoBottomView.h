//
//  OAInfoBottomView.h
//  OsmAnd
//
//  Created by Paul on 03.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OAInfoBottomViewDelegate <NSObject>

- (void) onLeftButtonPressed;
- (void) onRightButtonPressed;
- (void) onCloseButtonPressed;

@end

@interface OAInfoBottomView : UIView

@property (nonatomic, weak) id<OAInfoBottomViewDelegate> delegate;

@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *closeButtonView;
@property (weak, nonatomic) IBOutlet UILabel *mainInfoLabel;

@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@end
