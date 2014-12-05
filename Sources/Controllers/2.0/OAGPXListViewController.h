//
//  OAGPXListViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 04.12.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"

@interface OAGPXListViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate, UIDocumentInteractionControllerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *favoriteTableView;
@property (weak, nonatomic) IBOutlet UIButton *favoritesButtonView;
@property (weak, nonatomic) IBOutlet UIButton *gpxButtonView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

- (IBAction)menuFavoriteClicked:(id)sender;
- (IBAction)menuGPXClicked:(id)sender;


@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;


@property NSTimeInterval lastUpdate;


@end
