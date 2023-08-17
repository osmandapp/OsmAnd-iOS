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

+ (OAWptPtAdapter *) createWptPt:(OAPOIAdapter *)amenity lang:(NSString *)lang;

+ (NSArray<OATravelSearchResult *> *) search:(NSString *)searchQuery;

+ (NSArray<NSString *> *) getTravelGuidesObfList;

+ (CLLocation *) getMapCenter;

@end
