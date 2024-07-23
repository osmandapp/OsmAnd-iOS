//
//  OAObservable.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAObservableProtocol.h"

@interface OAObservable : NSObject <OAObservableProtocol>

- (void)registerObserver:(id<OAObserverProtocol>)observer;
- (void)unregisterObserver:(id<OAObserverProtocol>)observer;

- (void)notifyEvent;
- (void)notifyEventWithKey:(id)key;

@end
