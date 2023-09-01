//
//  OATravelGuidesHelper.h
//  OsmAnd
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAPOIAdapter.h"
#import "OAGPXDocumentPrimitivesAdapter.h"

@class OATravelSearchResult, OAPOIAdapter;


@interface OAFoundAmenity : NSObject

@property (nonatomic) NSString *file;
@property (nonatomic) OAPOIAdapter *amenity;

- (instancetype) initWithFile:(NSString *)file amenity:(OAPOIAdapter *)amenity;

@end


@interface OATravelGuidesHelper : NSObject

+ (NSArray<OAFoundAmenity *> *) searchAmenity:(double)lat lon:(double)lon reader:(NSString *)reader radius:(int)radius searchFilter:(NSString *)searchFilter publish:(BOOL(^)(OAPOIAdapter *poi))publish;

+ (void) searchAmenity:(NSString *)searchQuerry categoryName:(NSString *)categoryName radius:(int)radius lat:(double)lat lon:(double)lon reader:(NSString *)reader publish:(BOOL(^)(OAPOIAdapter *poi))publish;

+ (void) searchAmenity:(int)x y:(int)y left:(int)left right:(int)right top:(int)top bottom:(int)bottom  reader:(NSString *)reader searchFilter:(NSString *)searchFilter publish:(BOOL(^)(OAPOIAdapter *poi))publish;

+ (OAWptPtAdapter *) createWptPt:(OAPOIAdapter *)amenity lang:(NSString *)lang;

+ (NSArray<NSString *> *) getTravelGuidesObfList;

+ (CLLocation *) getMapCenter;

+ (NSString *) getPatrialContent:(NSString *)content;

+ (NSString *) normalizeFileUrl:(NSString *)url;

@end
