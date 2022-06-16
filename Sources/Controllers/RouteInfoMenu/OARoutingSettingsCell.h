//
//  OARoutingSettingsCell.h
//  OsmAnd
//
//  Created by Paul on 02/10/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OARoutingSettingsCellDelegate <NSObject>

- (void) onOptionsButtonPressed;

@end

@interface OARoutingSettingsCell : UITableViewCell

@property (nonatomic, weak) id<OARoutingSettingsCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *optionsButton;
@property (weak, nonatomic) IBOutlet UIButton *soundButton;

@end
