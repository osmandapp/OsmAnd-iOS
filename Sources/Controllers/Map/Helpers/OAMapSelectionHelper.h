//
//  OAMapSelectionHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class MapSelectionResult, OAPOI, ClickableWay;

@interface OAMapSelectionHelper : NSObject

- (MapSelectionResult *)collectObjectsFromMap:(CGPoint)point showUnknownLocation:(BOOL)showUnknownLocation;

+ (OAPOI *)findAmenity:(CLLocation *)latLon names:(NSArray<NSString *> *)names obfId:(uint64_t)obfId;
+ (OAPOI *)findAmenity:(CLLocation *)latLon names:(NSArray<NSString *> *)names obfId:(uint64_t)obfId radius:(int)radius;
+ (NSArray<OAPOI *> *)findAmenities:(CLLocation *)latLon;
+ (OAPOI *)findAmenityByOsmId:(CLLocation *)latLon obfId:(uint64_t)obfId;
+ (OAPOI *)findAmenityByOsmId:(NSArray<OAPOI *> *)amenities obfId:(uint64_t)obfId point:(CLLocation *)point;
+ (OAPOI *)findAmenityByName:(NSArray<OAPOI *> *)amenities names:(NSArray<NSString *> *)names;

- (BOOL) showContextMenuForSearchResult:(OAPOI *)poi filename:(NSString *)filename;

@end


NS_ASSUME_NONNULL_END
