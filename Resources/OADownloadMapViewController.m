//
//  OADownloadMapViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADownloadMapViewController.h"
#import "Localization.h"
#include "OASizes.h"

#include "OAMenuSimpleCell.h"

@interface OADownloadMapViewController() <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;



@end

@implementation OADownloadMapViewController
{
    NSDictionary *_data;
    
}

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"download_map");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    //_settings = [OAAppSettings sharedManager];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = UIColor.yellowColor;
    //[self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
    //[self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:kFooterId];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupView];
    [self.tableView reloadData];
}

- (UIView *) getTopView
{
    return _navBarView;
}

- (UIView *) getMiddleView
{
    return _tableView;
}

- (CGFloat) getNavBarHeight
{
    return defaultNavBarHeight;
}

- (void) adjustViews
{
    CGRect buttonFrame = _backButton.frame;
    CGRect titleFrame = _titleView.frame;
    CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
    buttonFrame.origin.y = statusBarHeight;
    titleFrame.origin.y = statusBarHeight;
    _backButton.frame = buttonFrame;
    _titleView.frame = titleFrame;
}

- (void) setupView
{
    [self applySafeAreaMargins];
    [self adjustViews];
    
    _data = [NSMutableDictionary dictionary];
    
    NSMutableArray *mapTypeArr = [NSMutableArray array];
    NSMutableArray *zoomLevelsArr = [NSMutableArray array];
    NSMutableArray *generalInfoArr = [NSMutableArray array];
    
    [mapTypeArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
                        
                        }];
    
    [zoomLevelsArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
                        
                        }];
    
    [zoomLevelsArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
    
    }];
    
    [zoomLevelsArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
    
    }];

    [generalInfoArr addObject:@{
                        @"type" : @"OASettingSwitchCell",
                        
                        }];
    
    [generalInfoArr addObject:@{
                        @"type" : @"OASettingSwitchCell",
    
    }];
}

- (IBAction)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MapView







#pragma mark - TableView

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
   return _data.count;;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString* const identifierCell = @"OAMenuSimpleCell";
    OAMenuSimpleCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMenuSimpleCell" owner:self options:nil];
        cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
        cell.backgroundColor = UIColor.clearColor;
        [cell.descriptionView setEnabled:NO];
    }
    cell.textView.text = @"Hello";
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}


@end
