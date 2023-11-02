//
//  OAPOIAdapter.h
//  OsmAnd
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@class OAPOI;

@interface OAPOIAdapter : NSObject

@property (nonatomic) OAPOI *object;

- (instancetype) initWithPOI:(OAPOI *)poi;

- (NSString *) name;
- (void) setName:(NSString *)name;

- (NSString *) subtype;

- (double) latitude;
- (void) setLatitude:(double)latitude;
- (double) longitude;
- (void) setLongitude:(double)longitude;
- (NSDictionary<NSString *, NSString *> *)getAdditionalInfo;
- (NSString *)getRef;
- (NSString *) getRouteId;
- (NSString *) getDescription:(NSString *)lang;

- (NSString *)getName:(NSString *)lang transliterate:(BOOL)transliterate;
- (NSArray<NSString *> *)getNames:(NSString *)tag defTag:(NSString *)defTag;
- (NSDictionary<NSString *, NSString *> *)getNamesMap:(BOOL)includeEn;
- (NSString *)getStrictTagContent:(NSString *)tag lang:(NSString *)lang;
- (NSString *)getTagContent:(NSString *)tag;
- (NSString *)getTagContent:(NSString *)tag lang:(NSString *)lang;
- (NSString *)getTagSuffix:(NSString *)tagPrefix;
- (NSString *)getLocalizedContent:(NSString *)tag lang:(NSString *)lang;

@end
