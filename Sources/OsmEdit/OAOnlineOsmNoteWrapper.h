//
//  OAOnlineOsmNoteWrapper.h
//  OsmAnd
//
//  Created by Paul on 4/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAOnlineOsmNote.h"

@interface OACommentWrapper : NSObject

@property (nonatomic, readonly) NSString *date;
@property (nonatomic, readonly) NSString *text;
@property (nonatomic, readonly) NSString *user;

-(id)initWithComment:(std::shared_ptr<const OAOnlineOsmNote::OAComment>)comment;

@end

@interface OAOnlineOsmNoteWrapper : NSObject

@property (nonatomic, readonly) BOOL local;
@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longitude;
@property (nonatomic, readonly) NSString *typeName;
@property (nonatomic, readonly) NSString *descr;
@property (nonatomic, readonly) NSArray *comments;
@property (nonatomic, readonly) long long identifier;
@property (nonatomic, readonly) BOOL opened;

-(id)initWithNote:(std::shared_ptr<const OAOnlineOsmNote>)note;

@end

