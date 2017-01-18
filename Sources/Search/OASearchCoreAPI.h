//
//  OASearchCoreAPI.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  revision 878491110c391829cc1f42eace8dc582cb35e08e

#import <Foundation/Foundation.h>

@class OASearchPhrase, OASearchResultMatcher;

@interface OASearchCoreAPI : NSObject

/**
 * @param p
 * @return order in which search core apis should be called, -1 means do not call
 */
- (int) getSearchPriority:(OASearchPhrase *)p;

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher;

/**
 * @param phrase
 * @return true if search more available (should be consistent with -1 search priority)
 */
- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase;


@end
