//
//  OAMapSettingsWikipediaLanguagesScreen.h
//  OsmAnd
//
//  Created by Skalii on 10.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAWikiLanguageItem;

@protocol OAWikipediaScreenDelegate <NSObject>

@required

- (void)updateSelectedLanguage;

@end

@interface OAWikiLanguageItem : NSObject

@property (nonatomic, readonly) NSString *locale;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic) BOOL checked;
@property (nonatomic, readonly) BOOL preferred;

- (instancetype)initWithLocale:(NSString *)locale title:(NSString *)title checked:(BOOL)checked preferred:(BOOL)preferred;
- (NSComparisonResult)compare:(OAWikiLanguageItem *)object;

@end

@interface OAMapSettingsWikipediaLanguagesScreen : OACompoundViewController

@property (nonatomic) id<OAWikipediaScreenDelegate> delegate;

@end