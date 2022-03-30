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

@property (weak, nonatomic) IBOutlet UILabel *footerTitleLabel;

@property (nonatomic) NSString *headerText;
@property (nonatomic) NSString *inputedText;

- (BOOL) isValidInputedValue:(NSString *)value;
- (void) reloadCellsWithoutInputField;
- (void) reloadAllCells;

@end
