//
//  OAMapStyleSettings.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OAMapStyleValueDataType)
{
    OABoolean,
    OAInteger,
    OAFloat,
    OAString,
    OAColor,
};


@interface OAMapStyleParameter : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *mapStyleName;
@property (nonatomic) NSString *category;
@property (nonatomic) NSString *categoryTitle;
@property (nonatomic) OAMapStyleValueDataType dataType;
@property (nonatomic) NSString *value;
@property (nonatomic) NSString *defaultValue;
@property (nonatomic) NSArray *possibleValues;

@end

@interface OAMapStyleSettings : NSObject

-(instancetype)initWithStyleName:(NSString *)mapStyleName;

-(NSArray *) getAllParameters;
-(NSArray *) getParameters:(NSString *)category;
-(void) saveParameters;
-(void) save:(OAMapStyleParameter *)parameter;

@end
