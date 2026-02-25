//
//  OAMapObject.h
//  OsmAnd
//
//  Created by Max Kojin on 09/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

static const NSInteger AMENITY_ID_RIGHT_SHIFT = 1;
static const NSInteger NON_AMENITY_ID_RIGHT_SHIFT = 7;

NS_ASSUME_NONNULL_BEGIN

@interface OAMapObject : NSObject

@property (nonatomic) long long obfId;

@property (nonatomic, nullable) NSString *name;
@property (nonatomic) NSString *enName;
@property (nonatomic, nullable) NSString *nameLocalized;
@property (nonatomic) NSMutableDictionary<NSString *, NSString *> *localizedNames;

@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic) NSMutableArray<NSNumber *> *x;
@property (nonatomic) NSMutableArray<NSNumber *> *y;

- (CLLocation *) getLocation;

- (void)addLocation:(int)x y:(int)y;
- (void)setName:(NSString * _Nullable)lang name:(NSString * _Nonnull)name;

- (void)copyNames:(NSString *)otherName otherEnName:(NSString *)otherEnName otherNames:(NSDictionary<NSString *, NSString *> *)otherNames overwrite:(BOOL)overwrite;
- (void)copyNames:(NSString *)otherName otherEnName:(NSString *)otherEnName otherNames:(NSDictionary<NSString *, NSString *> *)otherNames;
- (void)copyNames:(OAMapObject *)s copyName:(BOOL)copyName copyEnName:(BOOL)copyEnName overwrite:(BOOL)overwrite;
- (void)copyNames:(OAMapObject *)s;

+ (BOOL)isNameLangTag:(NSString *)tag;

+ (void)parseNamesJSON:(NSString *)json
                object:(OAMapObject *)object;

@end

NS_ASSUME_NONNULL_END
