//
//  OAPOIAdapter.h
//  OsmAnd
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@interface OAPOIAdapter : NSObject

@property (nonatomic) id object;

- (instancetype) initWithPOI:(id)poi;

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

- (NSArray<NSString *> *)getNames:(NSString *)tag defTag:(NSString *)defTag;
- (NSDictionary<NSString *, NSString *> *)getNamesMap:(BOOL)includeEn;
- (NSString *)getStrictTagContent:(NSString *)tag lang:(NSString *)lang;
- (NSString *)getTagContent:(NSString *)tag;
- (NSString *)getTagContent:(NSString *)tag lang:(NSString *)lang;
- (NSString *)getLocalizedContent:(NSString *)tag lang:(NSString *)lang;

@end
