//
//  OAObserver.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservableProtocol.h"
#import "OAObserverProtocol.h"

@interface OAAutoObserverProxy : NSObject <OAObserverProtocol>

- (id)initWith:(id<OAObserverProtocol>)owner_;
- (id)initWith:(id<OAObserverProtocol>)owner_ withHandler:(SEL)selector_;

@property(weak, readonly) id<OAObserverProtocol> owner;
@property(weak, readonly) SEL handler;

@property(weak, readonly) id<OAObservableProtocol> observable;
- (void)observe:(id<OAObservableProtocol>)observable;

- (void)handleObservedEvent;
- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer;
- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer withKey:(id)key;
- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value;

@end
