//
//  OACoordinatesWidget.h
//  OsmAnd Maps
//
//  Created by nnngrach on 13.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OABaseWidgetView.h"

typedef NS_ENUM(NSInteger, EOACoordinatesWidgetType) {
    EOACoordinatesWidgetTypeCurrentLocation = 0,
    EOACoordinatesWidgetTypeMapCenter
};


@interface OACoordinatesWidget : OABaseWidgetView

- (instancetype) initWithType:(EOACoordinatesWidgetType)type;
- (BOOL) isVisible;

@end
