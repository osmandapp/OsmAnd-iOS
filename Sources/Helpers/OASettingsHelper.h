//
//  OASettingsHelper.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    EOAGlobal = 0,
    EOAProfile,
    EOAPlugin,
    EOAData,
    EOAFile,
    EOAQuickAction,
    EOAPoiUIFilters,
    EOAMapSources,
    EOAAvoidRoads
} EOASettingsItemType;

@interface OASettingsHelper : NSObject

@end

#pragma mark - OASettingsItem

@interface OASettingsItem : NSObject

@property (nonatomic, assign) EOASettingsItemType type;
@property (nonatomic, assign) BOOL shouldReplace;

-(instancetype)initWithType:(EOASettingsItemType)type;
-(instancetype)initWithType:(EOASettingsItemType)type json:(NSDictionary*)json;
-(EOASettingsItemType)getType;
-(void)readFromJSON:(NSDictionary*)json;
-(void)writeToJSON:(NSDictionary*)json;

@end

#pragma mark - OAStreamSettingsItem

@interface OAStreamSettingsItem : OASettingsItem

@property (nonatomic, assign) NSInputStream* inputStream;
@property (nonatomic, assign) NSString* name;

@end

#pragma mark - DataSettingsItem

@interface DataSettingsItem : OAStreamSettingsItem



@end
