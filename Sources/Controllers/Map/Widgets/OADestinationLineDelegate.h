//
//  OADestinationLineDelegate.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 21.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OADestinationsLineWidget.h"

NS_ASSUME_NONNULL_BEGIN

@interface OADestinationLineDelegate : NSObject<CALayerDelegate>

@property (nonatomic, strong) OADestinationsLineWidget *destinationLine;

- (id)initWithDestinationLine:(OADestinationsLineWidget*)destinationLine;

@end

NS_ASSUME_NONNULL_END
