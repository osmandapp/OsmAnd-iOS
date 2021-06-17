//
//  OAActionAddProfileViewController.m
//  OsmAnd
//
//  Created by nnngrach on 24.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAActionAddProfileViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OAMenuSimpleCell.h"
#import "OASizes.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "OAMapSource.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OAMapStyleTitles.h"
#import "OAProfileDataObject.h"
#import "OAProfileDataUtils.h"

@interface OAActionAddProfileViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OAActionAddProfileViewController
{
    NSMutableArray<NSString *> *_initialValues;
    NSArray<OAProfileDataObject *> *_data;
}

- (instancetype)initWithNames:(NSMutableArray<NSString *> *)names
{
    self = [super init];
    if (self) {
        _initialValues = names;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self commonInit];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 55., 0.0, 0.0);
    [self.tableView setEditing:YES];
    [self.backBtn setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
    [self.backBtn setTintColor:UIColor.whiteColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self applySafeAreaMargins];
}

-(void) commonInit
{
    _data = [OAProfileDataUtils getDataObjects:[OAApplicationMode allPossibleValues]];
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"select_application_profile");
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (IBAction)backPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneButtonPressed:(id)sender
{
    NSArray *selectedItems = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *arr = [NSMutableArray new];
    for (NSIndexPath *path in selectedItems)
    {
        OAProfileDataObject *profile = _data[path.row];
        [arr addObject:@{@"name" : profile.name, @"profile" : profile.stringKey, @"img" : profile.iconName, @"iconColor" : [NSNumber numberWithInt:profile.iconColor]}];
    }
    if (self.delegate)
        [self.delegate onProfileSelected:[NSArray arrayWithArray:arr]];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAProfileDataObject *item = _data[indexPath.row];
    OAMenuSimpleCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
        cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        cell.textView.text = item.name;
        cell.descriptionView.text = item.descr;
        cell.imgView.image = [UIImage templateImageNamed:item.iconName];
        cell.imgView.tintColor = UIColorFromRGB(item.iconColor);
        cell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        if ([_initialValues containsObject:item.stringKey])
        {
            [_tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [_initialValues removeObject:item.stringKey];
        }
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"app_profiles");
}

@end
