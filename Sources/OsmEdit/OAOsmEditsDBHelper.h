//
//  OAOsmEditsDBHelper.h
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAOpenStreetMapPoint;

@interface OAOsmEditsDBHelper : NSObject

+ (OAOsmEditsDBHelper *)sharedDatabase;

-(NSArray<OAOpenStreetMapPoint *> *) getOpenstreetmapPoints;
-(void)addOpenstreetmap:(OAOpenStreetMapPoint *)point;
-(void)deletePOI:(OAOpenStreetMapPoint *) point;
-(long) getMinID;

@end

NS_ASSUME_NONNULL_END
