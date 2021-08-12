//
//  OAWikiMenuViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOIViewController.h"

@class OAWikiMenuViewController;

@protocol OAWikiMenuDelegate <NSObject>

@optional
- (void)openWiki:(OAWikiMenuViewController *)sender;

@end

@interface OAWikiMenuViewController : OAPOIViewController

@property (weak, nonatomic) id<OAWikiMenuDelegate> menuDelegate;

- (id)initWithPOI:(OAPOI *)poi content:(NSString *)content;

@end
