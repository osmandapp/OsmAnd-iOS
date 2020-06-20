//
//  OAProfileAppearanceViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 17.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileAppearanceViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAApplicationMode.h"

#import "OATextInputCell.h"

#define kInputCell @"OATextInputCell"

@interface OAProfileAppearanceViewController() <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAProfileAppearanceViewController
{
    OAApplicationMode *_profile;
    NSDictionary *_data;
    CALayer *_horizontalLine;
}

- (instancetype) initWithProfile:(OAApplicationMode *)profile
{
    self = [super init];
    if (self) {
        _profile = profile;
        [self commonInit];
    }
    return self;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
    
    
}

- (void) generateData
{
}

-(void) applyLocalization
{
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
    _titleLabel.text = OALocalizedString(@"new_profile");
    //[_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal]];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.frame = CGRectMake(0.0, _navBarView.bounds.size.height, self.view.bounds.size.width, 0.5);
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    [_navBarView.layer addSublayer:_horizontalLine];
    
    [self setupNavBar];
    [self setupView];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
}

- (void) setupNavBar
{
    UIImage *img = nil;
    NSString *imgName = _profile.smallIconDark;
    if (imgName)
        img = [UIImage imageNamed:imgName];
    _profileIconImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _profileIconImageView.tintColor = UIColorFromRGB(0x732EEB);
    _profileIconView.layer.cornerRadius = _profileIconView.frame.size.height/2;
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    
    NSMutableArray *profileNameArr = [NSMutableArray array];
    NSMutableArray *profileAppearanceArr = [NSMutableArray array];
    NSMutableArray *profileMapAppearanceArr = [NSMutableArray array];
    

    [profileNameArr addObject:@{
        @"type" : kInputCell,
        @"title" : OALocalizedString(@"enter_profile_name"),
    }];
    
    [profileAppearanceArr addObject:@{
        @"title" : OALocalizedString(@"preview_of_selected_zoom_levels"),
    }];
    [profileAppearanceArr addObject:@{
        @"title" : OALocalizedString(@"rec_interval_minimum"),
    }];
    
    [profileMapAppearanceArr addObject:@{
        @"title" : OALocalizedString(@"shared_string_maximum"),
    }];
    [profileMapAppearanceArr addObject:@{
        @"title" : OALocalizedString(@"shared_string_maximum"),
    }];
    
    [tableData addObject:profileNameArr];
    [tableData addObject:profileAppearanceArr];
    [tableData addObject:profileMapAppearanceArr];
    _data = @{
        @"tableData" : tableData,
    };
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (IBAction) cancelButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) saveButtonClicked:(id)sender
{
    NSLog(@"Save profile");
}

#pragma mark - Table View

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data[@"tableData"] count];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_data[@"tableData"][section] count];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath { 
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    return cell;
}



@end
