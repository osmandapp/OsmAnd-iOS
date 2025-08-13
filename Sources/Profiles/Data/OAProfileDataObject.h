//
//  OAProfileDataObject.h
//  OsmAnd
//
//  Created by Paul on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAProfileDataObject : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *descr;
@property (nonatomic, readonly) NSString *iconName;
@property (nonatomic, readonly) NSString *stringKey;
@property (nonatomic) BOOL isSelected;
@property (nonatomic, readonly) BOOL isEnabled;
@property (nonatomic) int iconColor;
@property (nonatomic) int customIconColor;

- (instancetype) initWithStringKey:(NSString *)stringKey name:(NSString *)name descr:(NSString *)descr iconName:(NSString *)iconName isSelected:(BOOL)isSelected;

- (NSComparisonResult)compare:(OAProfileDataObject *)other;

@end
