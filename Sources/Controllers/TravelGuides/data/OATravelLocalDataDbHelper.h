//
//  OATravelLocalDataDbHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 26/09/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OATravelSearchHistoryItem, OATravelArticle;

@interface OATravelLocalDataDbHelper : NSObject

+ (OATravelLocalDataDbHelper *)sharedDatabase;

- (NSDictionary<NSString *, OATravelSearchHistoryItem *> *) getAllHistoryMap;
- (void) addHistoryItem:(OATravelSearchHistoryItem *)item;
- (void) updateHistoryItem:(OATravelSearchHistoryItem *)item;
- (void) removeHistoryItem:(OATravelSearchHistoryItem *)item;
- (void) clearAllHistory;

- (NSArray<OATravelArticle *> *) readSavedArticles;
- (BOOL) hasSavedArticles;
- (void) addSavedArticle:(OATravelArticle *)article;
- (void) removeSavedArticle:(OATravelArticle *)article;
- (void) updateSavedArticle:(OATravelArticle *)oldArticle newArticle:(OATravelArticle *)newArticle;

@end
