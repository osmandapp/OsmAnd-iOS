//
//  OAMapSource.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAMapSource : NSObject <NSCopying, NSCoding>

- (id)initWithResource:(NSString*)resourceId
        andSubresource:(NSString*)subresourceId;

@property(readonly) NSString* resourceId;
@property(readonly) NSString* subresourceId;

@end
