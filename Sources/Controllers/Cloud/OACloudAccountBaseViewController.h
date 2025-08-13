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
#import "OAFilledButtonCell.h"
#import "OADividerCell.h"
#import "OAButtonTableViewCell.h"

@interface OACloudAccountBaseViewController : OABaseBigTitleSettingsViewController

@property (nonatomic, assign) long lastTimeCodeSent;
@property (nonatomic) NSString *errorMessage;

- (NSString *) getTextFieldValue;
- (BOOL) isValidInputValue:(NSString *)value;
- (void) checkEmailValidity;
- (void) showErrorMessage:(NSString *)message;
- (BOOL) needFullReload:(NSString *)text;

- (void) updateScreen;

@end
