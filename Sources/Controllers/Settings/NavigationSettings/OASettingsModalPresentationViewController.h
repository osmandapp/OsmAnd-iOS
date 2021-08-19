//
//  OASettingsModalPresentationViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 27.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAApplicationMode.h"

@protocol OAVehicleParametersSettingDelegate <NSObject>

- (void) onSettingsChanged;

@end

@interface OASettingsModalPresentationViewController : OACompoundViewController<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) id<OAVehicleParametersSettingDelegate> delegate;
@property (nonatomic) OAApplicationMode *appMode;

- (instancetype) initWithAppMode:(OAApplicationMode *)am;
- (CGFloat) heightForLabel:(NSString *)text;
- (UIView *) getTableHeaderViewWithText:(NSString *)text;

@end
