//
//  OAMapStyleSettings.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAApplicationMode.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>

typedef NS_ENUM(NSInteger, OAMapStyleValueDataType)
{
    OABoolean,
    OAInteger,
    OAFloat,
    OAString,
    OAColor,
};

@interface OAMapStyleParameterValue : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *title;

@end

@interface OAMapStyleParameter : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *mapStyleName;
@property (nonatomic) NSString *mapPresetName;
@property (nonatomic) NSString *category;
@property (nonatomic) OAMapStyleValueDataType dataType;
@property (nonatomic) NSString *value;
@property (nonatomic) NSString *defaultValue;
@property (nonatomic) NSArray *possibleValues;
@property (nonatomic) NSArray *possibleValuesUnsorted;

- (NSString *)getValueTitle;

@end

@interface OAMapStyleSettings : NSObject

-(instancetype)initWithStyleName:(NSString *)mapStyleName mapPresetName:(NSString *)mapPresetName;

+ (OAMapStyleSettings *)sharedInstance;

-(NSArray *) getAllParameters;
-(OAMapStyleParameter *) getParameter:(NSString *)name;

-(NSArray *) getAllCategories;
-(NSString *) getCategoryTitle:(NSString *)categoryName;
-(NSArray *) getParameters:(NSString *)category;

-(BOOL) getVisibilityForCategoryName:(NSString *)categoryName;
-(void) setVisibility:(BOOL)isVisible forCategoryName:(NSString *)name;
- (BOOL) isAllParametersHiddenForCategoryName:(NSString *)name;

-(BOOL) getVisibilityForParameterName:(NSString *)parameterName;
-(void) setVisibility:(BOOL)isVisible forParameterName:(NSString *)parameterName;

-(void) saveParameters;
-(void) save:(OAMapStyleParameter *)parameter;

@end
