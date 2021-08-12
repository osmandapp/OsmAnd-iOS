//
//  OAFavoriteImportViewController.h
//  OsmAnd
//
//  Created by Alexey on 2/6/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@interface OAFavoriteImportViewController : OACompoundViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *favoriteTableView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *importButton;
@property (weak, nonatomic) IBOutlet UIView *navBarView;

@property NSMutableArray* ignoredNames;
@property NSString* conflictedName;

@property (nonatomic, readonly) BOOL handled;

- (instancetype)initFor:(NSURL*)url;

- (IBAction)cancelClicked:(id)sender;
- (IBAction)importClicked:(id)sender;


@end
