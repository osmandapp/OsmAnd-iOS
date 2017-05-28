//
//  OASearchResult.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchResult.java
//  git revision 5da5d0d41d977acc31473eb7051b4ff0f4f8d118

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAObjectType.h"
#import "OAGPXDocument.h"

#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/GeoInfoDocument.h>

@class OASearchPhrase;

@interface OASearchResult : NSObject

// search phrase that makes search result valid
@property (nonatomic) OASearchPhrase *requiredSearchPhrase;

@property (nonatomic) NSObject *object;
@property (nonatomic, assign) std::shared_ptr<const OsmAnd::Amenity> amenity;
@property (nonatomic, assign) std::shared_ptr<const OsmAnd::IFavoriteLocation> favorite;
@property (nonatomic, assign) std::shared_ptr<const OsmAnd::GeoInfoDocument::LocationMark> wpt;

@property (nonatomic) EOAObjectType objectType;
@property (nonatomic) NSString *resourceId;

@property (nonatomic) double priority;
@property (nonatomic) double priorityDistance;
@property (nonatomic) NSString *wordsSpan ;
@property (nonatomic) OASearchResult *parentSearchResult;
@property (nonatomic) NSMutableSet<NSString *> *otherWordsMatch;
@property (nonatomic) BOOL firstUnknownWordMatches;

@property (nonatomic) CLLocation *location;
@property (nonatomic) int preferredZoom;
@property (nonatomic) NSString *localeName;
@property (nonatomic) NSString *alternateName;

@property (nonatomic) NSMutableArray<NSString *> *otherNames;

@property (nonatomic) NSString *localeRelatedObjectName;
@property (nonatomic) NSObject *relatedObject;
@property (nonatomic) NSString *relatedResourceId;
@property (nonatomic, assign) std::shared_ptr<const OsmAnd::GeoInfoDocument> relatedGpx;
@property (nonatomic) double distRelatedObjectName;


- (instancetype)initWithPhrase:(OASearchPhrase *)sp;

- (int) getFoundWordCount;
- (double) getSearchDistance:(CLLocation *)location;
- (double) getSearchDistance:(CLLocation *)location pd:(double)pd;

@end
