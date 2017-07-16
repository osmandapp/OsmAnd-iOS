//
//  OAVoiceRouter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OARoutingHelper;

@interface OAVoiceRouter : NSObject

- (instancetype)initWithHelper:(OARoutingHelper *)router;
- (void) updateAppMode;

@end
