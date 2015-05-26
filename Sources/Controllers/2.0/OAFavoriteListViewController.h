//
//  OAFavoriteListViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"

@interface OAFavoriteListViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate, UIDocumentInteractionControllerDelegate, UIAlertViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *favoriteTableView;

@property (weak, nonatomic) IBOutlet UIView *mainToolbarView;
@property (weak, nonatomic) IBOutlet UIButton *favoritesButtonView;
@property (weak, nonatomic) IBOutlet UIButton *gpxButtonView;

@property (weak, nonatomic) IBOutlet UIView *editToolbarView;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;
@property (weak, nonatomic) IBOutlet UIButton *groupButton;
@property (weak, nonatomic) IBOutlet UIButton *colorButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (weak, nonatomic) IBOutlet UIButton *directionButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

- (IBAction)menuFavoriteClicked:(id)sender;
- (IBAction)menuGPXClicked:(id)sender;


@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;


@property NSTimeInterval lastUpdate;


@end
