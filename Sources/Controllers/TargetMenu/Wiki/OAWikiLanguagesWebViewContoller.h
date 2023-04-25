//
//  OAWikiLanguagesWebViewContoller.h
//  OsmAnd
//
//  Created by Skalii on 06.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@protocol OAWikiLanguagesWebDelegate

- (void)onLocaleSelected:(NSString *)locale;

@end

@interface OAWikiLanguagesWebViewContoller : OABaseNavbarViewController

- (instancetype)initWithSelectedLocale:(NSString *)selectedLocale
                      availableLocales:(NSArray<NSString *> *)availableLocales
                      preferredLocales:(NSArray<NSString *> *)preferredLocales;

@property(nonatomic, weak) id<OAWikiLanguagesWebDelegate> delegate;

@end
