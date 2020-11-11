//
//  OAInfoBottomView.h
//  OsmAnd
//
//  Created by Paul on 03.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMeasurementEditingContext.h"

typedef NS_ENUM(NSInteger, EOABottomInfoViewType) {
    EOABottomInfoViewTypeMove = 0,
    EOABottomInfoViewTypeAddBefore,
    EOABottomInfoViewTypeAddAfter
};

@protocol OAInfoBottomViewDelegate <NSObject>

- (void) onLeftButtonPressed;
- (void) onRightButtonPressed;
- (void) onCloseButtonPressed;

- (void) onAddOneMorePointPressed:(EOAAddPointMode)mode;

@end

@interface OAInfoBottomView : UIView

@property (nonatomic, weak) id<OAInfoBottomViewDelegate> delegate;

@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *closeButtonView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (nonatomic) NSString *headerViewText;

- (instancetype) initWithType:(EOABottomInfoViewType)type;

- (CGFloat) getViewHeight;

@end
