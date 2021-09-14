//
//  OAMapStyleSettings.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kHorseRoutesAttr @"horseRoutes"
#define kPisteRoutesAttr @"pisteRoutes"
#define kAlpineHikingAttr @"alpineHiking"
#define kShowMtbRoutesAttr @"showMtbRoutes"
#define kShowCycleRoutesAttr @"showCycleRoutes"
#define kWhiteWaterSportsAttr @"whiteWaterSports"
#define kHikingRoutesOsmcAttr @"hikingRoutesOSMC"
#define kCycleNodeNetworkRoutesAttr @"showCycleNodeNetworkRoutes"
#define kTravelRoutesAttr @"travel_routes"

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
@property (nonatomic) NSString *storedValue;
@property (nonatomic) NSString *defaultValue;
@property (nonatomic) NSArray<OAMapStyleParameterValue *> *possibleValues;
@property (nonatomic) NSArray<OAMapStyleParameterValue *> *possibleValuesUnsorted;

- (NSString *) getValueTitle;

@end

@interface OAMapStyleSettings : NSObject

- (instancetype) initWithStyleName:(NSString *)mapStyleName mapPresetName:(NSString *)mapPresetName;

+ (OAMapStyleSettings *) sharedInstance;

- (void) loadParameters;
- (NSArray<OAMapStyleParameter *> *) getAllParameters;
- (OAMapStyleParameter *) getParameter:(NSString *)name;

- (NSArray<NSString *> *) getAllCategories;
- (NSString *) getCategoryTitle:(NSString *)categoryName;
- (NSArray<OAMapStyleParameter *> *) getParameters:(NSString *)category;
- (NSArray<OAMapStyleParameter *> *) getParameters:(NSString *)category sorted:(BOOL)sorted;

- (BOOL) isCategoryEnabled:(NSString *)categoryName;
- (void) setCategoryEnabled:(BOOL)isVisible categoryName:(NSString *)categoryName;

- (void) saveParameters;
- (void) save:(OAMapStyleParameter *)parameter;
- (void) save:(OAMapStyleParameter *)parameter refreshMap:(BOOL)refreshMap;

- (void) resetMapStyleForAppMode:(NSString *)mapPresetName;

@end
