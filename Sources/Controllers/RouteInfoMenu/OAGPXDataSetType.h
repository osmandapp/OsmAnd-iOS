//
//  OAGPXDataSetType.h
//  OsmAnd
//
//  Created by Skalii on 09.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAGPXDataSetType : NSObject

+ (NSString *)getTitle:(NSInteger)type;
+ (NSString *)getIconName:(NSInteger)type;
+ (NSString *)getDataKey:(NSInteger)type;
+ (UIColor *)getTextColor:(NSInteger)type;
+ (UIColor *)getFillColor:(NSInteger)type;
+ (NSString *)getMainUnitY:(NSInteger)type;

@end
