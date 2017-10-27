//
//  OAMapInfoWidgetsFactory.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OATextInfoWidget;

@interface OAMapInfoWidgetsFactory : NSObject

- (OATextInfoWidget *) createAltitudeControl;

@end
