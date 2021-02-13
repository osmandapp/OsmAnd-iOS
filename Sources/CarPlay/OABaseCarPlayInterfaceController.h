//
//  OABaseCarPlayInterfaceController.h
//  OsmAnd Maps
//
//  Created by Paul on 12.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CPInterfaceController;

API_AVAILABLE(ios(12.0))
@interface OABaseCarPlayInterfaceController : NSObject

@property (nonatomic, readonly) CPInterfaceController *interfaceController;

- (instancetype) initWithInterfaceController:(CPInterfaceController *)interfaceController;

- (void) present;

@end

NS_ASSUME_NONNULL_END
