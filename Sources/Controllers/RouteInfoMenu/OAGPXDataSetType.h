//
//  OAGPXDataSetType.h
//  OsmAnd
//
//  Created by Skalii on 09.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAGPXDataSetType : NSObject

+ (NSString *)getTitle:(NSInteger)dst;
+ (NSString *)getIconName:(NSInteger)dst;
+ (NSString *)getDataKey:(NSInteger)dst;
+ (UIColor *)getTextColor:(NSInteger)dst;
+ (UIColor *)getFillColor:(NSInteger)dst;
+ (NSString *)getMainUnitY:(NSInteger)dst;
+ (NSString *)getFieldTypeNameByWidgetId:(NSString *)widgetId;

@end
