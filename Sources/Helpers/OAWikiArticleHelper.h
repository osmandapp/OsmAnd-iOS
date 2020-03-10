//
//  OAWikiArticleHelper.h
//  OsmAnd
//
//  Created by Paul on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAResourcesBaseViewController.h"
#import <Foundation/Foundation.h>

@class OAWorldRegion;

@interface OAWikiArticleHelper : NSObject

+ (OAWorldRegion *) findWikiRegion:(OAWorldRegion *)mapRegion;
+ (RepositoryResourceItem *) findResourceItem:(OAWorldRegion *)worldRegion;

+ (void) showWikiArticle:(CLLocationCoordinate2D)location url:(NSString *)url;

@end
