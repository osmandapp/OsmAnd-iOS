//
//  OAOsmBaseStorage.h
//  OsmAnd
//
//  Created by Paul on 2/8/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/osm/edit/OsmBaseStorage
//  git revision db3b280a26eaf721222ec918e8c0baf4dca9b1fd

#import <Foundation/Foundation.h>
#import <libxml/tree.h>
#import "OAPOIParser.h"
#import "OrderedDictionary.h"

@class OAEntityId;
@class OAEntityInfo;
@class OAEntity;

@protocol OABaseStorageParserDelegate <NSObject>

@required
- (void)parserFinished;

@optional
- (void)encounteredError:(NSError *)error;

@end

@interface OAOsmBaseStorage : NSObject

@property(nonatomic) BOOL error;
@property(nonatomic, weak) id<OABaseStorageParserDelegate> delegate;

- (void)parseResponseSync:(NSString*)textToParse;

-(OrderedDictionary<OAEntityId *, OAEntityInfo *> *) getRegisteredEntityInfo;
-(OrderedDictionary<OAEntityId *, OAEntity *> *) getRegisteredEntities;

-(void) setConvertTagsToLC:(BOOL)convertTagsToLC;

@end

