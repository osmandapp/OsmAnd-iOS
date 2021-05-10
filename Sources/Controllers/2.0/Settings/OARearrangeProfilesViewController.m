//
//  OARearrangeProfilesViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 20.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARearrangeProfilesViewController.h"
#import "OADeleteButtonTableViewCell.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kAllApplicationProfilesSection 0
#define kHeaderViewFont [UIFont systemFontOfSize:15.0]

@interface OAEditProfileItem : NSObject

@property (nonatomic) int order;
@property (nonatomic) OAApplicationMode *appMode;

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode;

@end

@implementation OAEditProfileItem

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super init];
    if (self) {
        _appMode = appMode;
        _order = appMode.getOrder;
    }
    return self;
}

@end

@interface OARearrangeProfilesViewController() <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OARearrangeProfilesViewController
{
    NSMutableArray<OAEditProfileItem *> *_appProfiles;
    NSMutableArray<OAEditProfileItem *> *_deletedProfiles;
    
    BOOL _hasChangesBeenMade;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (UIView *) getTopView
{
    return _navBar;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    _appProfiles = [[NSMutableArray alloc] init];
    _deletedProfiles = [[NSMutableArray alloc] init];
    
    for (OAApplicationMode *am in OAApplicationMode.allPossibleValues)
    {
        [_appProfiles addObject:[[OAEditProfileItem alloc] initWithAppMode:am]];
    }
}

- (void) applyLocalization
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
    [_tableView setEditing:YES];
    
    [self.navigationController.interactivePopGestureRecognizer addTarget:self
                                                                  action:@selector(swipeToCloseRecognized:)];
}

- (void) swipeToCloseRecognized:(UIGestureRecognizer *)recognizer
{
    if (_hasChangesBeenMade)
    {
        recognizer.enabled = NO;
        recognizer.enabled = YES;
        [self showChangesAlert];
    }
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"rearrange_profile_descr") font:kHeaderViewFont textColor:UIColorFromRGB(color_text_footer) lineSpacing:6.0 isTitle:NO];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"rearrange_profile_descr") font:kHeaderViewFont textColor:UIColorFromRGB(color_text_footer) lineSpacing:6.0 isTitle:NO];
        [_tableView reloadData];
    } completion:nil];
}

- (OAEditProfileItem *) getItem:(NSIndexPath *)indexPath
{
    BOOL isAllModes = indexPath.section == kAllApplicationProfilesSection;
    return isAllModes ? _appProfiles[indexPath.row] : _deletedProfiles[indexPath.row];
}

- (void)showChangesAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_editing_lost_changes_title") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_exit") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction) cancelButtonClicked:(id)sender
{
    if (_hasChangesBeenMade)
    {
        [self showChangesAlert];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction) doneButtonClicked:(id)sender
{
    NSMutableArray<OAApplicationMode *> *deletedModes = [NSMutableArray new];
    for (OAEditProfileItem *item in _deletedProfiles)
        [deletedModes addObject:item.appMode];

    [OAApplicationMode deleteCustomModes:deletedModes];
    
    NSMutableDictionary<NSString *, OAEditProfileItem *> *itemMapping = [NSMutableDictionary new];
    for (OAEditProfileItem *item in _appProfiles)
         [itemMapping setObject:item forKey:item.appMode.stringKey];
    
    for (OAApplicationMode *am in OAApplicationMode.allPossibleValues)
    {
        OAEditProfileItem *editItem = itemMapping[am.stringKey];
        if (editItem)
            [am setOrder:editItem.order];
    }
    [OAApplicationMode reorderAppModes];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - TableView

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kAllApplicationProfilesSection)
        return _appProfiles.count;
    else
        return _deletedProfiles.count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    BOOL isAllProfiles = indexPath.section == kAllApplicationProfilesSection;
    OAApplicationMode *mode = isAllProfiles ? _appProfiles[indexPath.row].appMode : _deletedProfiles[indexPath.row].appMode;
    
    NSString* const identifierCell = [OADeleteButtonTableViewCell getCellIdentifier];
    OADeleteButtonTableViewCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADeleteButtonTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OADeleteButtonTableViewCell *)[nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsMake(0.0, 58.0, 0.0, 0.0);
    }
    if (cell)
    {
        cell.titleLabel.text = mode.toHumanString;
        NSString *imageName = @"";
        if (isAllProfiles)
            imageName = mode.isCustomProfile ? @"ic_custom_delete" : @"ic_custom_delete_disable";
        else
            imageName = @"ic_custom_undo_button";
        
        cell.iconImageView.image = [mode.getIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconImageView.tintColor = UIColorFromRGB(mode.getIconColor);
        [cell.deleteButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [cell.deleteButton setUserInteractionEnabled:mode.isCustomProfile];
        cell.deleteButton.tag = indexPath.section << 10 | indexPath.row;
        [cell.deleteButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == kAllApplicationProfilesSection;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section != kAllApplicationProfilesSection)
        return sourceIndexPath;
    return proposedDestinationIndexPath;
}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == kAllApplicationProfilesSection;
}

- (void)updateProfileIndexes
{
    for (int i = 0; i < _appProfiles.count; i++)
    {
        _appProfiles[i].order = i;
    }
}

- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    _hasChangesBeenMade = YES;
    OAEditProfileItem *item = [self getItem:sourceIndexPath];
    // Deferr the data update until the animation is complete
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [_tableView reloadData];
    }];
    [_appProfiles removeObjectAtIndex:sourceIndexPath.row];
    [_appProfiles insertObject:item atIndex:destinationIndexPath.row];
    [self updateProfileIndexes];
    [CATransaction commit];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == kAllApplicationProfilesSection ? OALocalizedString(@"all_application_profiles") : OALocalizedString(@"osm_deleted");
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == kAllApplicationProfilesSection ? @"" : OALocalizedString(@"after_tapping_done");
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView * headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor  = UIColorFromRGB(color_text_footer);
    }
}

- (void) actionButtonPressed:(UIButton *)sender
{
    _hasChangesBeenMade = YES;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    if (indexPath.section == kAllApplicationProfilesSection)
    {
        [self deleteMode:indexPath];
    }
    else
    {
        [self restoreMode:indexPath];
    }
}

- (void) deleteMode:(NSIndexPath *)indexPath
{
    OAEditProfileItem *am = _appProfiles[indexPath.row];
    [_appProfiles removeObject:am];
    [_deletedProfiles addObject:am];
    [self updateProfileIndexes];
    NSIndexPath *targetPath = [NSIndexPath indexPathForRow:_deletedProfiles.count - 1 inSection:1];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [_tableView reloadData];
    }];
    [_tableView beginUpdates];
    [_tableView moveRowAtIndexPath:indexPath toIndexPath:targetPath];
    [_tableView endUpdates];
    [CATransaction commit];
}

- (void) restoreMode:(NSIndexPath *)indexPath
{
    OAEditProfileItem *am = _deletedProfiles[indexPath.row];
    int order = am.order;
    order = order > _appProfiles.count ? (int) _appProfiles.count : order;
    NSIndexPath *targetPath = [NSIndexPath indexPathForRow:order inSection:kAllApplicationProfilesSection];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [_tableView reloadData];
    }];
    [_deletedProfiles removeObjectAtIndex:indexPath.row];
    [_appProfiles insertObject:am atIndex:order];
    [_tableView beginUpdates];
    [_tableView moveRowAtIndexPath:indexPath toIndexPath:targetPath];
    [_tableView endUpdates];
    [CATransaction commit];
}

@end
