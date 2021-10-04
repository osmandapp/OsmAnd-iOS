//
//  OAGPXAppearanceCollection.h
//  OsmAnd
//
//  Created by Paul on 1/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAMapViewController;

typedef NS_ENUM(NSInteger, EOAGPXSplitType) {
    EOAGPXSplitTypeNone = -1,
    EOAGPXSplitTypeDistance = 1,
    EOAGPXSplitTypeTime = 2
};

@interface OAGPXTrackAppearance : NSObject

@property (nonatomic) NSString *key;
@property (nonatomic) NSString *title;

@end

@interface OAGPXTrackColor : OAGPXTrackAppearance

@property (nonatomic) UIColor *color;
@property (nonatomic) NSInteger colorValue;

- (instancetype)initWithKey:(NSString *)key value:(NSInteger)value;

@end

@interface OAGPXTrackWidth : OAGPXTrackAppearance

@property (nonatomic) NSString *icon;
@property (nonatomic) NSArray<NSArray<NSNumber *> *> *allValues;
@property (nonatomic) NSString *customValue;

- (instancetype)initWithKey:(NSString *)key value:(NSObject *)value;
+ (instancetype)getDefault;

- (BOOL)isCustom;

@end

@interface OAGPXTrackSplitInterval : OAGPXTrackAppearance

@property (nonatomic) EOAGPXSplitType type;
@property (nonatomic) NSArray<NSNumber *> *allValues;
@property (nonatomic) NSString *customValue;

- (instancetype)initWithType:(EOAGPXSplitType)type value:(NSString *)value;
+ (instancetype)getDefault;

- (BOOL)isCustom;
+ (NSString *)toTypeName:(EOAGPXSplitType)splitType;

@end

@interface OAGPXAppearanceCollection : NSObject

@property (nonatomic) NSString *gpxName;

- (NSArray<OAGPXTrackColor *> *)getAvailableColors;
- (NSArray<OAGPXTrackWidth *> *)getAvailableWidth;
- (NSArray<OAGPXTrackSplitInterval *> *)getAvailableSplitIntervals;

- (OAGPXTrackColor *)getColorForValue:(NSInteger)value;
- (OAGPXTrackWidth *)getWidthForValue:(NSString *)value;
- (OAGPXTrackSplitInterval *)getSplitIntervalForType:(EOAGPXSplitType)type;

@end
