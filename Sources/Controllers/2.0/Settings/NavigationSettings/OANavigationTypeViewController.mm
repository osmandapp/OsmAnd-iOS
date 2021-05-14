//
//  OANavigationTypeViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 22.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavigationTypeViewController.h"
#import "OAIconTextTableViewCell.h"
#import "OAProfileDataObject.h"
#import "OAProfileNavigationSettingsViewController.h"
#import "OAApplicationMode.h"
#import "OAProfileDataUtils.h"
#import "OAAppSettings.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16

@interface OANavigationTypeViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OANavigationTypeViewController
{
    NSString *_currentSelectedKey;
    NSArray<OARoutingProfileDataObject *> *_sortedRoutingProfiles;
    NSArray<NSString *> *_fileNames;
    NSArray<NSArray *> *_data;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self) {
        _currentSelectedKey = appMode.getRoutingProfile;
    }
    return self;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"nav_type_title");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupTableHeaderViewWithText:OALocalizedString(@"select_nav_profile_dialog_message")];
    [self setupView];
}

- (void) setupView
{
    _sortedRoutingProfiles = [OAProfileDataUtils getSortedRoutingProfiles];
    NSMutableArray *tableData = [NSMutableArray new];
    NSString *lastFileName = _sortedRoutingProfiles.firstObject.fileName;
    NSMutableArray *sectionData = [NSMutableArray new];
    NSMutableArray *fileNames = [NSMutableArray new];
    for (NSInteger i = 0; i < _sortedRoutingProfiles.count; i++)
    {
        OARoutingProfileDataObject *profile = _sortedRoutingProfiles[i];
        if ((lastFileName == nil && profile.fileName == nil) || [lastFileName isEqualToString:profile.fileName])
        {
            [sectionData addObject:@{
                @"type" : @"OAIconTextCell",
                @"title" : profile.name,
                @"profile_ind" : @(i),
                @"icon" : profile.iconName,
            }];
        }
        else
        {
            [tableData addObject:[NSArray arrayWithArray:sectionData]];
            [sectionData removeAllObjects];
            lastFileName = profile.fileName;
            [fileNames addObject:lastFileName];
            [sectionData addObject:@{
                @"type" : @"OAIconTextCell",
                @"title" : profile.name,
                @"profile_ind" : @(i),
                @"icon" : profile.iconName,
            }];
        }
    }
    [tableData addObject:[NSArray arrayWithArray:sectionData]];
    _fileNames = [NSArray arrayWithArray:fileNames];
    _data = [NSArray arrayWithArray:tableData];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupTableHeaderViewWithText:OALocalizedString(@"select_nav_profile_dialog_message")];
        [self.tableView reloadData];
    } completion:nil];
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
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OAIconTextCell"])
    {
        static NSString* const identifierCell = @"OAIconTextCell";
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.arrowIconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
            cell.arrowIconView.tintColor = UIColorFromRGB(self.appMode.getIconColor);
            cell.iconView.image = [UIImage templateImageNamed:item[@"icon"]];
            BOOL isSelected = [_sortedRoutingProfiles[[item[@"profile_ind"] integerValue]].stringKey isEqualToString:_currentSelectedKey];
            cell.arrowIconView.hidden = !isSelected;
            cell.iconView.tintColor = isSelected ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    OARoutingProfileDataObject *profileData = _sortedRoutingProfiles[[item[@"profile_ind"] integerValue]];
    if (profileData)
    {
        int routeService;
        if ([profileData.stringKey isEqualToString:@"STRAIGHT_LINE_MODE"])
            routeService = STRAIGHT;
        else if ([profileData.stringKey isEqualToString:@"DIRECT_TO_MODE"])
            routeService = DIRECT_TO;
//        else if (profileKey.equals(RoutingProfilesResources.BROUTER_MODE.name())) {
//            routeService = RouteProvider.RouteService.BROUTER;
        else
            routeService = OSMAND;
        OAAppSettings *settings = OAAppSettings.sharedManager;
        [settings.routingProfile set:profileData.stringKey mode:self.appMode];
        [settings.routerService set:routeService mode:self.appMode];
        if (self.delegate)
            [self.delegate onSettingsChanged];
        [self dismissViewController];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"osmand_routing");
    else
        return _fileNames[section - 1].lastPathComponent;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == tableView.numberOfSections - 1)
        return OALocalizedString(@"import_routing_file_descr");
    else
        return @"";
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

-(void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

@end
