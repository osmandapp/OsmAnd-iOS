//
//  OAObservableProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OAObserverProtocol;

@protocol OAObservableProtocol <NSObject>

@required
- (void)registerObserver:(id<OAObserverProtocol>)observer;
- (void)unregisterObserver:(id<OAObserverProtocol>)observer;

@optional
- (void)notifyEvent;
- (void)notifyEventWithKey:(id)key;
- (void)notifyEventWithKey:(id)key andValue:(id)value;
- (void)notifyEventWithKey:(id)key value1:(id)value1 value2:(id)value2;

@end
