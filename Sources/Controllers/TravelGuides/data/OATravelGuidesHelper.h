//
//  OATravelGuidesHelper.h
//  OsmAnd
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OATravelSearchResult, OAPOI, OATravelArticle, OAGPXDocumentAdapter, OASWptPt, OASGpxDataItem, OATravelGpx;

@interface OAFoundAmenity : NSObject

@property (nonatomic) NSString *file;
@property (nonatomic) OAPOI *amenity;

- (instancetype) initWithFile:(NSString *)file amenity:(OAPOI *)amenity;

@end


@interface OATravelGuidesHelper : NSObject

+ (void) searchAmenity:(double)lat lon:(double)lon reader:(NSString *)reader radius:(int)radius searchFilters:(NSArray<NSString *> *)searchFilters publish:(BOOL(^)(OAPOI *poi))publish;

+ (void) searchAmenity:(NSString *)searchQuery categoryNames:(NSArray<NSString *> *)categoryNames radius:(int)radius lat:(double)lat lon:(double)lon reader:(NSString *)reader publish:(BOOL(^)(OAPOI *poi))publish;

+ (void) searchAmenity:(int)x y:(int)y left:(int)left right:(int)right top:(int)top bottom:(int)bottom  reader:(NSString *)reader searchFilters:(NSArray<NSString *> *)searchFilters publish:(BOOL(^)(OAPOI *poi))publish;

+ (void) searchAmenity:(NSString *)searchQuery x:(int)x y:(int)y left:(int)left right:(int)right top:(int)top bottom:(int)bottom reader:(NSString *)reader searchFilters:(NSArray<NSString *> *)searchFilters publish:(BOOL(^)(OAPOI *poi))publish;

+ (void) showContextMenuWithLatitude:(double)latitude longitude:(double)longitude;

+ (OASWptPt *) createWptPt:(OAPOI *)amenity lang:(NSString *)lang;

+ (NSArray<NSString *> *) getTravelGuidesObfList;

+ (CLLocation *) getMapCenter;

+ (NSString *) getPatrialContent:(NSString *)content;

+ (NSString *) normalizeFileUrl:(NSString *)url;

+ (NSString *) createGpxFile:(OATravelArticle *)article fileName:(NSString *)fileName;

+ (OAGPXDocumentAdapter *) buildGpxFile:(NSArray<NSString *> *)readers article:(OATravelArticle *)article;

+ (OASGpxDataItem *) buildGpx:(NSString *)path title:(NSString *)title document:(OAGPXDocumentAdapter *)document;

+ (NSString *) getSelectedGPXFilePath:(NSString *)fileName;

@end
