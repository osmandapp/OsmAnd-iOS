//
//  OAOsmBugsDBHelper.h
//  OsmAnd
//
//  Created by Paul on 1/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/osmedit/OsmBugsDbHelper.java
//  git revision 042c22d408f8d8c00b27736014073bcdde971e9e

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAOsmNotePoint;

@interface OAOsmBugsDBHelper : NSObject

+ (OAOsmBugsDBHelper *)sharedDatabase;

-(NSArray<OAOsmNotePoint *> *) getOsmBugsPoints;
-(void) updateOsmBug:(long) identifier text:(NSString *)text;
-(void) addOsmbugs:(OAOsmNotePoint *)point;
-(void) deleteAllBugModifications:(OAOsmNotePoint *) point;
-(long long) getMinID;

- (void) updateOsmBugLocation:(long long)identifier newPosition:(CLLocationCoordinate2D)newPosition;

- (long)getLastModifiedTime;
- (void) setLastModifiedTime:(long)lastModified;

@end

NS_ASSUME_NONNULL_END
