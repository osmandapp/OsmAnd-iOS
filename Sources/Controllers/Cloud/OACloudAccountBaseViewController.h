//
//  OACloudAccountBaseViewController.h
//  OsmAnd Maps
//
//  Created by nnngrach on 17.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATableViewCustomHeaderView.h"
#import "OADescrTitleCell.h"
#import "OAInputCellWithTitle.h"
#import "OAFilledButtonCell.h"
#import "OADividerCell.h"
#import "OAButtonCell.h"

@interface OACloudAccountBaseViewController : OABaseBigTitleSettingsViewController

@property (nonatomic , assign) long lastTimeCodeSent;

- (NSString *) getTextFieldValue;
- (BOOL) isValidInputValue:(NSString *)value;

@end
