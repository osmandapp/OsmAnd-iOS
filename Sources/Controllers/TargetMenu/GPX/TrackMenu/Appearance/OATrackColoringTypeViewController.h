//
//  OATrackColoringTypeViewController.h
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OATrackAppearanceItem;

@protocol OATrackColoringTypeDelegate

- (void)onColoringTypeSelected:(OATrackAppearanceItem *)selectedItem;

@end

@interface OATrackColoringTypeViewController : OABaseNavbarViewController

- (instancetype)initWithAvailableColoringTypes:(NSArray<OATrackAppearanceItem *> *)availableColoringTypes selectedItem:(OATrackAppearanceItem *)selectedItem;

@property (nonatomic, weak) id<OATrackColoringTypeDelegate> delegate;

@end
