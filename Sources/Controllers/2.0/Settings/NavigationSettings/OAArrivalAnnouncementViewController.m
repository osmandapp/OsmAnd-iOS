//
//  OAArrivalAnnouncementViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAArrivalAnnouncementViewController.h"
#import "OASettingsTitleTableViewCell.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16

@interface OAArrivalAnnouncementViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAArrivalAnnouncementViewController
{
    NSArray<NSArray *> *_data;
    NSArray<NSNumber *> *_arrivalNames;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
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
    _arrivalNames =  @[ OALocalizedString(@"arrival_distance_factor_early"),
        OALocalizedString(@"arrival_distance_factor_normally"),
        OALocalizedString(@"arrival_distance_factor_late"),
        OALocalizedString(@"arrival_distance_factor_at_last") ];
    NSMutableArray *dataArr = [NSMutableArray array];
    for (int i = 0; i < _arrivalNames.count; i++)
    {
        [dataArr addObject:
         @{
           @"name" : _arrivalNames[i],
           @"title" : _arrivalNames[i],
           @"isSelected" : @NO,
           @"type" : @"OASettingsTitleCell"
         }];
    }
    _data = [NSArray arrayWithObject:dataArr];
}

-(void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"arrival_distance");
    self.subtitleLabel.text = OALocalizedString(@"app_mode_car");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupTableHeaderViewWithText:OALocalizedString(@"arrival_announcement_frequency")];
    [self setupView];
}

- (void) setupView
{
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupTableHeaderViewWithText:OALocalizedString(@"arrival_announcement_frequency")];
        [self.tableView reloadData];
    } completion:nil];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OASettingsTitleCell"])
    {
        static NSString* const identifierCell = @"OASettingsTitleCell";
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_checkmark_default"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.hidden = ![item[@"isSelected"] boolValue];
        }
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
