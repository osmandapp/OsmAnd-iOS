//
//  OAWebViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 27.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OABaseWebViewController.h"

@interface OAWebViewController : OABaseWebViewController

@property NSString *urlString;
@property BOOL *isCssOverriding;
@property BOOL *isDarkModeSupported;

- (id)initWithUrl:(NSString*)url;
- (id)initWithUrlAndTitle:(NSString*)url title:(NSString *) title;

@end
