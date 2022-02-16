//
//  OAProfileDataObject.h
//  OsmAnd
//
//  Created by Paul on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EOARoutingProfilesResource)
{
    EOARoutingProfilesResourceUndefined = -1,
    EOARoutingProfilesResourceDirectTo = 0,
    EOARoutingProfilesResourceStraightLine,
    EOARoutingProfilesResourceBrouter,
    EOARoutingProfilesResourceCar,
    EOARoutingProfilesResourcePedestrian,
    EOARoutingProfilesResourceBicycle,
    EOARoutingProfilesResourceSki,
    EOARoutingProfilesResourcePublicTransport,
    EOARoutingProfilesResourceBoat,
    EOARoutingProfilesResourceHorsebackriding,
    EOARoutingProfilesResourceGeocoding
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

- (NSComparisonResult)compare:(OAProfileDataObject *)other;

@end

@interface OARoutingProfileDataObject : OAProfileDataObject

@property (nonatomic) NSString *fileName;

- (instancetype) initWithStringKey:(NSString *)stringKey name:(NSString *)name descr:(NSString *)descr iconName:(NSString *)iconName isSelected:(BOOL)isSelected fileName:(NSString *) fileName;

- (instancetype) initWithResource:(EOARoutingProfilesResource)res;

+ (NSString *) getLocalizedName:(EOARoutingProfilesResource)res;
+ (NSString *) getIconName:(EOARoutingProfilesResource)res;
+ (NSString *) getProfileKey:(EOARoutingProfilesResource)type;
+ (OARoutingProfileDataObject *) getRoutingProfileDataByName:(NSString *)key;
+ (EOARoutingProfilesResource) getValueOf:(NSString *)key;

+ (BOOL) isRpValue:(NSString *)value;

@end
