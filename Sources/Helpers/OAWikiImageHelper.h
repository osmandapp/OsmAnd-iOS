//
//  OAWikiImageHelper.h
//  OsmAnd
//
//  Created by Skalii on 05.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WIKIDATA_API_ENDPOINT @"https://www.wikidata.org/w/api.php"
#define WIKIMEDIA_API_ENDPOINT @"https://commons.wikimedia.org/w/api.php"
#define WIKIDATA_ACTION @"?action=wbgetclaims&property=P18&entity="
#define WIKIMEDIA_ACTION @"?action=query&list=categorymembers&cmtitle="
#define CM_LIMIT @"&cmlimit=100"
#define FORMAT_JSON @"&format=json"
#define IMAGE_BASE_URL @"https://commons.wikimedia.org/wiki/Special:FilePath/"

#define WIKIDATA_PREFIX @"Q"
#define WIKIMEDIA_FILE @"File:"
#define WIKIMEDIA_CATEGORY @"Category:"
#define WIKIMEDIA_WIDTH @"?width="

#define THUMB_SIZE 480

static NSString * const OSMAND_API_ENDPOINT = @"https://osmand.net/api/wiki_place?";
static const NSInteger DEPT_CAT_LIMIT = 1;
static const BOOL USE_OSMAND_WIKI_API = YES;

@class OARowInfo;
@class OAAbstractCard;

@interface OAWikiImageHelper : NSObject

+ (OAWikiImageHelper *)sharedInstance;

- (void)sendNearbyWikiImagesRequest:(OARowInfo *)nearbyImagesRowInfo targetObj:(id)targetObj addOtherImagesOnComplete:(void (^)(NSMutableArray <OAAbstractCard *> *cards))addOtherImagesOnComplete;

@end
