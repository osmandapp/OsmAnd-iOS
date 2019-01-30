//
//  OAOsmNotePoint.h
//  OsmAnd
//
//  Created by Paul on 1/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmPoint.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAOsmNotePoint : OAOsmPoint <OAOsmPointProtocol>

-(NSString *)getText;
-(NSString *) getAuthor;

-(void)setId:(long)identifier;
-(void)setText:(NSString *)text;
-(void)setLatitude:(double) latitude;
-(void)setLongitude:(double)longitude;
-(void)setAuthor:(NSString *)author;

@end

NS_ASSUME_NONNULL_END
