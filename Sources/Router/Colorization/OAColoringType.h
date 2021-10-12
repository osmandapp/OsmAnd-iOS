//
//  OAColoringType.h
//  OsmAnd Maps
//
//  Created by Paul on 25.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAGPXDocument, OAGradientScaleType;

@interface OAColoringType : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *iconName;

+ (OAColoringType *) DEFAULT;
+ (OAColoringType *) CUSTOM_COLOR;
+ (OAColoringType *) TRACK_SOLID;
+ (OAColoringType *) SPEED;
+ (OAColoringType *) ALTITUDE;
+ (OAColoringType *) SLOPE;
+ (OAColoringType *) ATTRIBUTE;

+ (NSArray<OAColoringType *> *) getRouteColoringTypes;
+ (NSArray<OAColoringType *> *) getTrackColoringTypes;

+ (OAColoringType *) getNonNullTrackColoringTypeByName:(NSString *)name;

- (BOOL) isAvailableForDrawingTrack:(OAGPXDocument *)selectedGpxFile attributeName:(NSString *)attributeName;

- (OAGradientScaleType *) toGradientScaleType;

<<<<<<< HEAD
=======
- (BOOL) isTrackSolid;
>>>>>>> 31d17e5d1ebb3d4d1d3eae3cf25bb9f7c40019c5
- (BOOL) isGradient;

@end

