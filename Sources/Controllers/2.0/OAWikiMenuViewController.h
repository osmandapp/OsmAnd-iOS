//
//  OAWikiMenuViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 26/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPoiViewController.h"

@class OAWikiMenuViewController;

@protocol OAWikiMenuDelegate <NSObject>

@optional
- (void)openWiki:(OAWikiMenuViewController *)sender;

@end

@interface OAWikiMenuViewController : OAPOIViewController

@property (weak, nonatomic) id<OAWikiMenuDelegate> menuDelegate;

- (id)initWithPOI:(OAPOI *)poi content:(NSString *)content;

@end
