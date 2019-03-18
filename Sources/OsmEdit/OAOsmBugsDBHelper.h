//
//  OAOsmBugsDBHelper.h
//  OsmAnd
//
//  Created by Paul on 1/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAOsmNotePoint;

@interface OAOsmBugsDBHelper : NSObject

+ (OAOsmBugsDBHelper *)sharedDatabase;

-(NSArray<OAOsmNotePoint *> *) getOsmBugsPoints;
-(void) updateOsmBug:(long) identifier text:(NSString *)text;
-(void)addOsmBug:(OAOsmNotePoint *)point;
-(void)deleteAllBugModifications:(OAOsmNotePoint *) point;
-(long) getMinID;

@end

NS_ASSUME_NONNULL_END
