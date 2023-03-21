//
//  OAWikipediaImagesSettingsViewController.h
//  OsmAnd
//
//  Created by Skalii on 17.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

@protocol OAWikipediaScreenDelegate;

@interface OAWikipediaImagesSettingsViewController : OABaseSettingsViewController

@property (nonatomic) id<OAWikipediaScreenDelegate> wikipediaDelegate;

@end
