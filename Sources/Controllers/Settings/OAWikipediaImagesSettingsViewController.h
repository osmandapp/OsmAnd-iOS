//
//  OAWikipediaImagesSettingsViewController.h
//  OsmAnd
//
//  Created by Skalii on 17.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

@protocol WikipediaScreenDelegate;

@interface OAWikipediaImagesSettingsViewController : OABaseSettingsViewController

@property (nonatomic) id<WikipediaScreenDelegate> wikipediaDelegate;

@end
