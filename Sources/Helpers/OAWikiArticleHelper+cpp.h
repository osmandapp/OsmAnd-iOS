//
//  OAWikiArticleHelper+cpp.h
//  OsmAnd
//
//  Created by nnngrach on 04.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAResourcesBaseViewController.h"
#import <Foundation/Foundation.h>

@interface OAWikiArticleHelper(cpp)

+ (OARepositoryResourceItem *) findResourceItem:(OAWorldRegion *)worldRegion;
+ (void) showHowToOpenWikiAlert:(OARepositoryResourceItem *)item url:(NSString *)url sourceView:(UIView *)sourceView;

@end
