//
//  OARearrangeProfilesViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 20.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARearrangeProfilesViewController.h"
#import "OAPointHeaderTableViewCell.h"
#import "OASettingsCheckmarkCell.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16

@interface OARearrangeProfilesViewController() <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OARearrangeProfilesViewController
{
    NSArray<NSArray *> *_data;
    NSArray<NSArray *> *_deletedProfiles;
    UIView *_tableHeaderView;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(UIView *) getTopView
{
    return _navBar;
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
    _titleLabel.text = OALocalizedString(@"rearrange_profiles");
    [_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.estimatedRowHeight = 48.;
    _tableView.tableHeaderView = _tableHeaderView;
    [self setupTableHeaderViewWithText:OALocalizedString(@"rearrange_profile_descr")];
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

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    
    NSMutableArray *allApplicationProfiles = [NSMutableArray array];
    NSMutableArray *deletedProfiles = [NSMutableArray array];
    [allApplicationProfiles addObject:@{
        @"title" : OALocalizedString(@"Profile 1"),
        @"icon" : @"ic_profile_browsemap"
    }];
    [allApplicationProfiles addObject:@{
        @"title" : OALocalizedString(@"Profile 2"),
        @"icon" : @"ic_profile_car"
    }];
    [allApplicationProfiles addObject:@{
        @"title" : OALocalizedString(@"Profile 3"),
        @"icon" : @"ic_profile_bicycle"
    }];
    [allApplicationProfiles addObject:@{
        @"title" : OALocalizedString(@"Profile 4"),
        @"icon" : @"ic_action_bus_dark"
    }];
    [allApplicationProfiles addObject:@{
        @"title" : OALocalizedString(@"Profile 5"),
        @"icon" : @"ic_profile_pedestrian"
    }];
    [allApplicationProfiles addObject:@{
        @"title" : OALocalizedString(@"Profile 6"),
        @"icon" : @"ic_action_horse"
    }];
    [allApplicationProfiles addObject:@{
        @"title" : OALocalizedString(@"Profile 7"),
        @"icon" : @"ic_action_pickup_truck"
    }];
    [deletedProfiles addObject:@{
        @"title" : OALocalizedString(@"Profile 8"),
        @"icon" : @"ic_action_aircraft"
    }];
    [tableData addObject:allApplicationProfiles];
    [tableData addObject:deletedProfiles];
    
    _data = [NSArray arrayWithArray:tableData];
}

- (void) setupTableHeaderViewWithText:(NSString *)text
{
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    CGFloat textHeight = [self heightForLabel:text];
    _tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, textHeight + kSidePadding)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, kSidePadding, textWidth, textHeight)];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:6];
    label.attributedText = [[NSAttributedString alloc] initWithString:text
                                                        attributes:@{NSParagraphStyleAttributeName : style,
                                                        NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer),
                                                        NSFontAttributeName : [UIFont systemFontOfSize:15.0],
                                                        NSBackgroundColorAttributeName : UIColor.clearColor}];
    label.textAlignment = NSTextAlignmentJustified;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _tableHeaderView.backgroundColor = UIColor.clearColor;
    [_tableHeaderView addSubview:label];
    _tableView.tableHeaderView = _tableHeaderView;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupTableHeaderViewWithText:OALocalizedString(@"rearrange_profile_descr")];
        [_tableView reloadData];
    } completion:nil];
}

- (IBAction) cancelButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) doneButtonClicked:(id)sender {
}

#pragma mark - TableView

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    static NSString* const identifierCell = @"OASettingsCheckmarkCell";
    OASettingsCheckmarkCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCheckmarkCell" owner:self options:nil];
        cell = (OASettingsCheckmarkCell *)[nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsMake(0.0, 58.0, 0.0, 0.0);
    }
    if (cell)
    {
        cell.titleLabel.text = item[@"title"];
        cell.checkmarkImageView.image = [UIImage imageNamed:@"ic_custom_delete"];
        cell.checkmarkImageView.hidden = NO;
        cell.iconImageView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconImageView.tintColor = UIColorFromRGB(color_chart_orange);
    }
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"all_application_profiles") : OALocalizedString(@"osm_deleted");
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? @"" : OALocalizedString(@"after_tapping_done");
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont systemFontOfSize:15.0];
    CGFloat textWidth = _tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, textWidth, CGFLOAT_MAX)];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.font = labelFont;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 6.0;
    style.alignment = NSTextAlignmentCenter;
    label.attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSParagraphStyleAttributeName : style}];
    [label sizeToFit];
    return label.frame.size.height;
}

@end
