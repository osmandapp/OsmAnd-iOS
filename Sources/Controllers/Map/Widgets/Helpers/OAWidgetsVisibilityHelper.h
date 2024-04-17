//
//  OAWidgetsVisibilityHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 04.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAWidgetsVisibilityHelper : NSObject

+ (instancetype) sharedInstance;

- (BOOL)shouldShowQuickActionButton;
- (BOOL)shouldShowMap3DButton;
- (BOOL)shouldShowFabButton;
- (BOOL)shouldShowTopCoordinatesWidget;
- (BOOL)shouldShowTopMapMarkersWidget;
- (BOOL)shouldShowBottomMenuButtons;
- (BOOL)shouldShowZoomButtons;
- (BOOL)shouldHideCompass;
- (BOOL)shouldShowTopButtons;
- (BOOL)shouldShowBackToLocationButton;
- (BOOL)shouldShowTopLanesWidget;

@end

NS_ASSUME_NONNULL_END
