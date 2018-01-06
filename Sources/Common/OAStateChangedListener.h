//
//  OAStateChangedListener.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OAStateChangedListener <NSObject>

@required
- (void) stateChanged:(id)change;

@end
