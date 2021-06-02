//
//  OABasePointEditingHandler.h
//  OsmAnd Maps
//
//  Created by Paul on 01.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAPointEditingData;


@interface OAPointEditingData : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *descr;
@property (nonatomic) NSString *address;
@property (nonatomic) UIColor *color;
@property (nonatomic) NSString *backgroundIcon;
@property (nonatomic) NSString *icon;
@property (nonatomic) NSString *category;

@end

@interface OABasePointEditingHandler : NSObject

- (UIColor *) getColor;
- (NSString *) getGroupTitle;
- (NSString *) getIcon;
- (NSString *) getBackgroundIcon;
- (NSString *) getName;
- (BOOL) isSpecialPoint;

- (void) deleteItem;
- (NSDictionary *)checkDuplicates:(NSString *)name group:(NSString *)group;

- (void) savePoint:(OAPointEditingData *)data newPoint:(BOOL)newPoint;

@end

NS_ASSUME_NONNULL_END
