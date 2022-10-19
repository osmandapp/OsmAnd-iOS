//
//  OAOpenstreetmapsDbHelper.h
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/osmedit/OpenstreetmapsDbHelper.java
//  git revision b2e637ae441908003348ba9ac02d6594ad4d8c67

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAOpenStreetMapPoint;

@interface OAOsmEditsDBHelper : NSObject

+ (OAOsmEditsDBHelper *)sharedDatabase;

-(NSArray<OAOpenStreetMapPoint *> *) getOpenstreetmapPoints;
-(void)addOpenstreetmap:(OAOpenStreetMapPoint *)point;
-(void)deletePOI:(OAOpenStreetMapPoint *) point;
-(long long) getMinID;

- (void) updateEditLocation:(long long) editId newPosition:(CLLocationCoordinate2D)newPosition;

- (long)getLastModifiedTime;
- (void) setLastModifiedTime:(long)lastModified;

@end

NS_ASSUME_NONNULL_END
