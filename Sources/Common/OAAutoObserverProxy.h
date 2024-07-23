//
//  OAObserver.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAObserverProtocol.h"

@protocol OAObservableProtocol;

@interface OAAutoObserverProxy : NSObject <OAObserverProtocol>

- (instancetype)initWith:(id<OAObserverProtocol>)owner;
- (instancetype)initWith:(id<OAObserverProtocol>)owner andObserve:(id<OAObservableProtocol>)observable;
- (instancetype)initWith:(id)owner withHandler:(SEL)selector;
- (instancetype)initWith:(id)owner withHandler:(SEL)selector andObserve:(id<OAObservableProtocol>)observable;;

@property(weak, readonly) id owner;
@property(readonly) SEL handler;

@property(weak, readonly) id<OAObservableProtocol> observable;
- (void)observe:(id<OAObservableProtocol>)observable;

- (void)handleObservedEvent;
- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer;
- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer withKey:(id)key;
- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value;

@property(readonly) BOOL isAttached;
- (BOOL)detach;

@end
