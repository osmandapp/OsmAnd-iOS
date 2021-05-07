//
//  OASearchResult.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchResult.java
//  git revision 35cc4a981a4dcdb2d5e16ec7c6e9346ba75b6a5b

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

// internal package fields (used for sorting)
@property (nonatomic) OASearchResult *parentSearchResult;
@property (nonatomic) NSString *wordsSpan;
@property (nonatomic) BOOL firstUnknownWordMatches;

@property (nonatomic) NSObject *object;
@property (nonatomic, assign) std::shared_ptr<const OsmAnd::Amenity> amenity;
@property (nonatomic, assign) std::shared_ptr<const OsmAnd::IFavoriteLocation> favorite;
@property (nonatomic, assign) std::shared_ptr<const OsmAnd::GeoInfoDocument::LocationMark> wpt;

@property (nonatomic) EOAObjectType objectType;
@property (nonatomic) NSString *resourceId;

@property (nonatomic) double priority;
@property (nonatomic) double priorityDistance;
@property (nonatomic) NSMutableSet<NSString *> *otherWordsMatch;
@property (nonatomic) BOOL unknownPhraseMatches;
@property (nonatomic) double unknownPhraseMatchWeight;

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
- (double) getSearchDistanceRound:(CLLocation *)location;
- (double) getSearchDistanceRound:(CLLocation *)location pd:(double)pd;
- (double) getSearchDistanceFloored:(CLLocation *)location;
- (double) getSearchDistanceFloored:(CLLocation *)location pd:(double)pd;

- (double) getSumPhraseMatchWeight;
- (int) getDepth;
- (OASearchResult *)setNewParentSearchResult:(OASearchResult *)parentSearchResult;

- (NSString *) toString;

@end
