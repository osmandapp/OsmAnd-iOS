//
//  OAPhrasesParser.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>
#import "OAPOIParser.h"

@protocol OAPhrasesParserDelegate <NSObject>

@required
- (void)parserFinished;

@optional
- (void)encounteredError:(NSError *)error;

@end


@interface OAPhrasesParser : NSObject


@property(nonatomic) NSDictionary *phrases;
@property(nonatomic) BOOL error;
@property(nonatomic, weak) id<OAPhrasesParserDelegate> delegate;
@property(nonatomic) NSString *fileName;

- (void)getPhrasesSync:(NSString*)fileName;
- (void)getPhrasesAsync:(NSString*)fileName;

@end
