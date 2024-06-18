//
//  OAOsmAndFormatterParams.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAOsmAndFormatterParams : NSObject

@property (nonatomic, assign) BOOL forceTrailingZerosInDecimalMainUnit;
@property (nonatomic, assign) int extraDecimalPrecision;
@property (nonatomic, assign) BOOL useLowerBound;

+ (instancetype)defaultParams;
+ (instancetype)useLowerBoundsParams;
+ (instancetype)noTrailingZerosParams;

- (instancetype)setTrailingZerosForMainUnit:(BOOL)forceTrailingZeros;

@end
