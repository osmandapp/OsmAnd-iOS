//
//  OARouteSegmentAttribute.h
//  OsmAnd
//
//  Created by Paul on 18.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OARouteSegmentAttribute : NSObject

@property (nonatomic, readonly) NSInteger color;
@property (nonatomic, readonly) NSString *propertyName;
@property (nonatomic, readonly) NSInteger slopeIndex;

- (instancetype) initWithPropertyName:(NSString *) propertyName color:(NSInteger) color slopeIndex:(NSInteger) slopeIndex boundariesClass:(NSArray<NSString *> *)boundariesClass;

@end
