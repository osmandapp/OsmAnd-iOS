//
//  OAObserverProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservableProtocol.h"

@protocol OAObserverProtocol <NSObject>

@optional
- (void)handleObservedEvent;
- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer;
- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer withKey:(id)key;
- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value;

@end
