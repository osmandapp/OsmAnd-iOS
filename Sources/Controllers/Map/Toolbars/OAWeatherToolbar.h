//
//  OAWeatherToolbar.h
//  OsmAnd
//
//  Created by Skalii on 03.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OABaseWidgetView.h"
#import "OAFoldersCollectionView.h"

@interface OAWeatherToolbar : OABaseWidgetView

@property (nonatomic) BOOL topControlsVisibleInLandscape;
@property (nonatomic) BOOL needsSettingsForToolbar;
@property (nonatomic, readonly) NSInteger selectedLayerIndex;

- (void)resetHandlersData;
- (void)reloadCollectionsView;
- (void)moveOutOfScreen;
- (void)moveToScreen;

+ (CGFloat)calculateY;
+ (CGFloat)calculateYOutScreen;
- (void)updateWidgetsInfo;

- (void)onFrameAnimatorsUpdated;

@end
