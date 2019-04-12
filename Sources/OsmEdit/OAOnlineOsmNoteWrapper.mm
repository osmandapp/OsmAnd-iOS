//
//  OAOnlineOsmNoteWrapper.m
//  OsmAnd
//
//  Created by Paul on 4/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOnlineOsmNoteWrapper.h"

@implementation OAOnlineOsmNoteWrapper

-(id)initWithNote:(std::shared_ptr<const OAOnlineOsmNote>)note
{
    self = [super init];
    if (self) {
        _identifier = note->getId();
        _local = note->isLocal();
        _opened = note->isOpened();
        _latitude = note->getLatitude();
        _longitude = note->getLongitude();
        _typeName = note->getTypeName().toNSString();
        _descr = note->getDescription().toNSString();
        _comments = [self getComments:note];
    }
    return self;
}

- (NSArray *)getComments:(std::shared_ptr<const OAOnlineOsmNote>)note
{
    NSMutableArray *arr = [NSMutableArray new];
    for (const auto& comment : note->getComments()) {
        [arr addObject:[[OACommentWrapper alloc] initWithComment:comment]];
    }
    return [NSArray arrayWithArray:arr];
}


@end

@implementation OACommentWrapper

-(id)initWithComment:(std::shared_ptr<const OAOnlineOsmNote::OAComment>)comment
{
    self = [super init];
    if (self) {
        if (comment != nullptr)
        {
            _user = comment->_user.toNSString();
            _date = comment->_date.toNSString();
            _text = comment->_text.toNSString();
        }
    }
    return self;
}

@end
