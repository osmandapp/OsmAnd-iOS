//
//  OAOcbfHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 24/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAOcbfHelper : NSObject

// completionHandler reports whether regions.ocbf actually changed
+ (void) downloadOcbfIfUpdated:(void (^)(BOOL updated))completionHandler;
+ (BOOL) isBundledOcbfNewer;

@end
