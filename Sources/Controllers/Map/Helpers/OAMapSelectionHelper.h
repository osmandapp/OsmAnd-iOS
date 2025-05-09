//
//  OAMapSelectionHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@class OAMapSelectionResult;

@interface OAMapSelectionHelper : NSObject

- (OAMapSelectionResult *) collectObjectsFromMap:(CGPoint)point showUnknownLocation:(BOOL)showUnknownLocation;

@end
