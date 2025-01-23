//
//  OAMapObject.h
//  OsmAnd
//
//  Created by Max Kojin on 09/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

//static const NSInteger AMENITY_ID_RIGHT_SHIFT = 1;
//static const NSInteger WAY_MODULO_REMAINDER = 1;

@interface OAMapObject : NSObject

@property (nonatomic) unsigned long long obfId;

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *enName;
////enName
////names

@property (nonatomic) NSString *nameLocalized;

@property (nonatomic) NSDictionary<NSString *, NSString *> *localizedNames;

@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
//

//
//- (NSString *)getName:(NSString *)lang transliterate:(BOOL)transliterate;
//- (NSArray<NSString *> *)getNames:(NSString *)tag defTag:(NSString *)defTag;
//- (NSDictionary<NSString *, NSString *> *)getNamesMap:(BOOL)includeEn;

@property (nonatomic) NSMutableArray<NSNumber *> *x;
@property (nonatomic) NSMutableArray<NSNumber *> *y;

- (void) addLocation:(int)x y:(int)y;
- (void) setName:(NSString *)lang name:(NSString *)name;

@end
