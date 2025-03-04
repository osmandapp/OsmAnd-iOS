//
//  OAWikiWebViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseWebViewController.h"

@class OAPOI;

NS_ASSUME_NONNULL_BEGIN

@interface OAWikiWebViewController : OABaseWebViewController

- (instancetype)initWithPoi:(OAPOI *)poi;
- (instancetype)initWithPoi:(OAPOI *)poi locale:(NSString *)locale;
- (instancetype)initWithURL:(NSURL *)url title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
