//
//  OASearchToolbarViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAToolbarViewController.h"

@protocol OASearchToolbarViewControllerProtocol
@required

- (void) searchToolbarOpenSearch;
- (void) searchToolbarClose;

@end

@interface OASearchToolbarViewController : OAToolbarViewController

@property (weak, nonatomic) IBOutlet UIButton *titleButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (nonatomic) NSString *toolbarTitle;

@property (weak, nonatomic) id<OASearchToolbarViewControllerProtocol> searchDelegate;

@end
