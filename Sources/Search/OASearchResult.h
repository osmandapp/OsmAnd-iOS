//
//  OASearchResult.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  revision 878491110c391829cc1f42eace8dc582cb35e08e

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAObjectType.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Data/Address.h>

typedef OsmAnd::ResourcesManager::LocalResource LocalResource;

@class OASearchPhrase;

@interface OASearchResult : NSObject

// search phrase that makes search result valid
@property (nonatomic) OASearchPhrase *requiredSearchPhrase;

@property (nonatomic) NSObject *object;
@property (nonatomic) EOAObjectType objectType;
@property (nonatomic, assign) std::shared_ptr<LocalResource> file;

@property (nonatomic) double priority;
@property (nonatomic) double priorityDistance;
@property (nonatomic) NSString *wordsSpan ;
@property (nonatomic) OASearchResult *parentSearchResult;
@property (nonatomic) NSMutableSet<NSString *> *otherWordsMatch;

@property (nonatomic) CLLocation *location;
@property (nonatomic) int preferredZoom;
@property (nonatomic) NSString *localeName;

@property (nonatomic) NSMutableArray<NSString *> *otherNames;

@property (nonatomic) NSString *localeRelatedObjectName;
@property (nonatomic) NSObject *relatedObject;
@property (nonatomic, assign) std::shared_ptr<LocalResource> relatedFile;
@property (nonatomic, assign) std::shared_ptr<OsmAnd::Address> relatedAddress;
@property (nonatomic) double distRelatedObjectName;


- (instancetype)initWithPhrase:(OASearchPhrase *)sp;

- (int) getFoundWordCount;
- (double) getSearchDistance:(CLLocation *)location;
- (double) getSearchDistance:(CLLocation *)location pd:(double)pd;

@end
