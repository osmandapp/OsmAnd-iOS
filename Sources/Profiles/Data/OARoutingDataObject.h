//
//  OARoutingDataObject.h
//  OsmAnd
//
//  Created by Skalii on 16.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAProfileDataObject.h"

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
    EOARoutingProfilesResourceTrain,
    EOARoutingProfilesResourceBoat,
    EOARoutingProfilesResourceHorsebackriding,
    EOARoutingProfilesResourceGeocoding,
    EOARoutingProfilesResourceMoped
};

@interface OARoutingDataObject : OAProfileDataObject

@property (nonatomic, readonly) NSString *fileName;
@property (nonatomic, readonly) NSString *derivedProfile;

- (instancetype) initWithStringKey:(NSString *)stringKey
                              name:(NSString *)name
                             descr:(NSString *)descr
                          iconName:(NSString *)iconName
                        isSelected:(BOOL)isSelected
                          fileName:(NSString *)fileName
                    derivedProfile:(NSString *)derivedProfile;

+ (NSString *) getLocalizedName:(EOARoutingProfilesResource)res;
+ (NSString *) getIconName:(EOARoutingProfilesResource)res;
+ (NSString *) getProfileKey:(EOARoutingProfilesResource)type;
+ (EOARoutingProfilesResource) getValueOf:(NSString *)key;

+ (BOOL) isRpValue:(NSString *)value;

@end
