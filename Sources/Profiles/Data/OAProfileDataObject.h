//
//  OAProfileDataObject.h
//  OsmAnd
//
//  Created by Paul on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAProfileDataObject : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *descr;
@property (nonatomic) NSString *iconName;
@property (nonatomic) NSString *stringKey;
@property (nonatomic) BOOL isSelected;
@property (nonatomic) BOOL isEnabled;
@property (nonatomic) int iconColor;

- (instancetype) initWithStringKey:(NSString *)stringKey name:(NSString *)name descr:(NSString *)descr iconName:(NSString *)iconName isSelected:(BOOL)isSelected;

- (NSComparisonResult)compare:(OAProfileDataObject *)other;

@end
