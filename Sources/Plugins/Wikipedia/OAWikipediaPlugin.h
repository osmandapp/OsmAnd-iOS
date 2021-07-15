//
//  OAWikipediaPlugin.h
//  OsmAnd
//
//  Created by Skalii on 02.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

@interface OAWikipediaPlugin : OAPlugin

- (void)updateWikipediaState;
- (BOOL)hasCustomSettings;
- (BOOL)hasCustomSettings:(OAApplicationMode *)profile;
- (BOOL)hasLanguagesFilter;
- (BOOL)hasLanguagesFilter:(OAApplicationMode *)profile;
- (BOOL)isShowAllLanguages;
- (BOOL)isShowAllLanguages:(OAApplicationMode *)mode;
- (void)setShowAllLanguages:(BOOL)showAllLanguages;
- (void)setShowAllLanguages:(OAApplicationMode *)mode showAllLanguages:(BOOL)showAllLanguages;
- (NSArray<NSString *> *)getLanguagesToShow;
- (NSArray<NSString *> *)getLanguagesToShow:(OAApplicationMode *)mode;
- (void)setLanguagesToShow:(NSArray<NSString *> *)languagesToShow;
- (void)setLanguagesToShow:(OAApplicationMode *)mode languagesToShow:(NSArray<NSString *> *)languagesToShow;
- (void)toggleWikipediaPoi:(BOOL)enable /*CallbackWithObject<Boolean> callback*/;
- (void)refreshWikiOnMap;
- (NSString *)getLanguagesSummary;
- (NSString *)getWikiArticleLanguage:(NSSet<NSString *> *)availableArticleLangs preferredLanguage:(NSString *)preferredLanguage;

@end