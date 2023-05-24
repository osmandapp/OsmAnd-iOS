//
//  OnlineTilesSettingsViewController.h
//  OsmAnd Maps
//
//  Created by igor on 30.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"
#import "OAResourcesBaseViewController.h"
#import "OAOnlineTilesEditingViewController.h"

@protocol OAOnlineTilesSettingsViewControllerDelegate <NSObject>

- (void) onMercatorChanged:(BOOL)isEllipticYTile;
- (void) onStorageFormatChanged:(EOASourceFormat)sourceFormat;

@end

@interface OAOnlineTilesSettingsViewController : OABaseNavbarViewController

@property (nonatomic) id<OAOnlineTilesSettingsViewControllerDelegate> delegate;

-(instancetype) initWithEllipticYTile:(BOOL)isEllipticYTile;
-(instancetype) initWithSourceFormat:(EOASourceFormat)sourceFormat;

@end
