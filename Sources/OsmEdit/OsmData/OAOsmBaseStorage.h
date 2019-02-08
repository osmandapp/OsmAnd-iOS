//
//  OAOsmBaseStorage.h
//  OsmAnd
//
//  Created by Paul on 2/8/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>
#import "OAPOIParser.h"


@protocol OABaseStorageParserDelegate <NSObject>

@required
- (void)parserFinished;

@optional
- (void)encounteredError:(NSError *)error;

@end

@interface OAOsmBaseStorage : NSObject

@property(nonatomic) BOOL error;
@property(nonatomic, weak) id<OABaseStorageParserDelegate> delegate;

- (void)getPhrasesSync:(NSString*)textToParse;
- (void)getPhrasesAsync:(NSString*)textToParse;

@end

