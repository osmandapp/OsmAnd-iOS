//
//  OAProfileDataObject.h
//  OsmAnd
//
//  Created by Paul on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EOARouringProfilesResource)
{
    EOARouringProfilesResourceDirectTo = 0,
    EOARouringProfilesResourceStraightLine,
    EOARouringProfilesResourceBrouter,
    EOARouringProfilesResourceCar,
    EOARouringProfilesResourcePedestrian,
    EOARouringProfilesResourceBicycle,
    EOARouringProfilesResourceSki,
    EOARouringProfilesResourcePublicTransport,
    EOARouringProfilesResourceBoat,
    EOARouringProfilesResourceGeocoding
};

@interface OAProfileDataObject : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *descr;
@property (nonatomic) NSString *iconName;
@property (nonatomic) NSString *stringKey;
@property (nonatomic) BOOL isSelected;
@property (nonatomic) BOOL isEnabled;
@property (nonatomic) int iconColor;

- (instancetype) initWithStringKey:(NSString *)stringKey name:(NSString *)name descr:(NSString *)descr iconName:(NSString *)iconName isSelected:(BOOL)isSelected;

@end

@interface OARoutingProfileDataObject : OAProfileDataObject

@property (nonatomic) NSString *fileName;

- (instancetype) initWithStringKey:(NSString *)stringKey name:(NSString *)name descr:(NSString *)descr iconName:(NSString *)iconName isSelected:(BOOL)isSelected fileName:(NSString *) fileName;

- (instancetype) initWithResource:(EOARouringProfilesResource)res;

+ (NSString *) getLocalizedName:(EOARouringProfilesResource)res;
+ (NSString *) getIconName:(EOARouringProfilesResource)res;
+ (NSString *) getProfileKey:(EOARouringProfilesResource)type;
+ (OARoutingProfileDataObject *) getRoutingProfileDataByName:(NSString *)key;

+ (BOOL) isRpValue:(NSString *)value;

@end
