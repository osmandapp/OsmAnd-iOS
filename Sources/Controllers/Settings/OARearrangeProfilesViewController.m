//
//  OARearrangeProfilesViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 20.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARearrangeProfilesViewController.h"
#import "OASimpleTableViewCell.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

#define kAllApplicationProfilesSection 0

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

@interface OARearrangeProfilesViewController() <OATableViewCellDelegate>

@end

@implementation OARearrangeProfilesViewController
{
    NSMutableArray<OAEditProfileItem *> *_appProfiles;
    NSMutableArray<OAEditProfileItem *> *_deletedProfiles;

    BOOL _hasChangesBeenMade;
}

#pragma mark - Initialization

- (void)commonInit
{
    _appProfiles = [NSMutableArray array];
    _deletedProfiles = [NSMutableArray array];

    for (OAApplicationMode *am in [OAApplicationMode allPossibleValues])
    {
        [_appProfiles addObject:[[OAEditProfileItem alloc] initWithAppMode:am]];
    }
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"rearrange_profiles");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return @[[self createRightNavbarButton:OALocalizedString(@"shared_string_done")
                                  iconName:nil
                                    action:@selector(onRightNavbarButtonPressed)
                                      menu:nil]];
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (NSString *)getCustomTableViewDescription
{
    return OALocalizedString(@"rearrange_profile_descr");
}

#pragma mark - UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.editing = YES;
    [self.navigationController.interactivePopGestureRecognizer addTarget:self
                                                                  action:@selector(swipeToCloseRecognized:)];
}

#pragma mark - Table data

- (OAEditProfileItem *) getItem:(NSIndexPath *)indexPath
{
    BOOL isAllModes = indexPath.section == kAllApplicationProfilesSection;
    return isAllModes ? _appProfiles[indexPath.row] : _deletedProfiles[indexPath.row];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return section == kAllApplicationProfilesSection ? OALocalizedString(@"all_application_profiles") : OALocalizedString(@"poi_remove_success");
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return section == kAllApplicationProfilesSection ? @"" : OALocalizedString(@"after_tapping_done");
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (section == kAllApplicationProfilesSection)
        return _appProfiles.count;
    else
        return _deletedProfiles.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    BOOL isAllProfiles = indexPath.section == kAllApplicationProfilesSection;
    OAApplicationMode *mode = isAllProfiles ? _appProfiles[indexPath.row].appMode : _deletedProfiles[indexPath.row].appMode;
    OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASimpleTableViewCell *) nib[0];
        [cell leftEditButtonVisibility:YES];
        [cell descriptionVisibility:NO];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (cell)
    {
        cell.titleLabel.text = mode.toHumanString;
        cell.leftIconView.image = [UIImage templateImageNamed:[mode getIconName]];
        cell.leftIconView.tintColor = [mode getProfileColor];

        NSString *imageName = !isAllProfiles ? @"ic_custom_undo_button" : [mode isCustomProfile] ? @"ic_custom_delete" : @"ic_custom_delete_disable";
        [cell.leftEditButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        cell.leftEditButton.enabled = mode.isCustomProfile;
        cell.leftEditButton.tag = indexPath.section << 10 | indexPath.row;
        [cell.leftEditButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.leftEditButton addTarget:self action:@selector(onEditButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}

- (NSInteger)sectionsCount
{
    return 2;
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == kAllApplicationProfilesSection;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == kAllApplicationProfilesSection;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    _hasChangesBeenMade = YES;
    OAEditProfileItem *item = [self getItem:sourceIndexPath];
    // Deferr the data update until the animation is complete
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.tableView reloadData];
    }];
    [_appProfiles removeObjectAtIndex:sourceIndexPath.row];
    [_appProfiles insertObject:item atIndex:destinationIndexPath.row];
    [self updateProfileIndexes];
    [CATransaction commit];
}

#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section != kAllApplicationProfilesSection)
        return sourceIndexPath;
    return proposedDestinationIndexPath;
}

#pragma mark - Additions

- (void)showChangesAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"exit_without_saving") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_exit") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateProfileIndexes
{
    for (int i = 0; i < _appProfiles.count; i++)
    {
        _appProfiles[i].order = i;
    }
}

- (void)deleteMode:(NSIndexPath *)indexPath
{
    OAEditProfileItem *am = _appProfiles[indexPath.row];
    [_appProfiles removeObject:am];
    [_deletedProfiles addObject:am];
    [self updateProfileIndexes];
    NSIndexPath *targetPath = [NSIndexPath indexPathForRow:_deletedProfiles.count - 1 inSection:1];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.tableView reloadData];
    }];
    [self.tableView beginUpdates];
    [self.tableView moveRowAtIndexPath:indexPath toIndexPath:targetPath];
    [self.tableView endUpdates];
    [CATransaction commit];
}

- (void)restoreMode:(NSIndexPath *)indexPath
{
    OAEditProfileItem *am = _deletedProfiles[indexPath.row];
    int order = am.order;
    order = order > _appProfiles.count ? (int) _appProfiles.count : order;
    NSIndexPath *targetPath = [NSIndexPath indexPathForRow:order inSection:kAllApplicationProfilesSection];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.tableView reloadData];
    }];
    [_deletedProfiles removeObjectAtIndex:indexPath.row];
    [_appProfiles insertObject:am atIndex:order];
    [self.tableView beginUpdates];
    [self.tableView moveRowAtIndexPath:indexPath toIndexPath:targetPath];
    [self.tableView endUpdates];
    [CATransaction commit];
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    if (_hasChangesBeenMade)
        [self showChangesAlert];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)onRightNavbarButtonPressed
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

- (void)swipeToCloseRecognized:(UIGestureRecognizer *)recognizer
{
    if (_hasChangesBeenMade)
    {
        recognizer.enabled = NO;
        recognizer.enabled = YES;
        [self showChangesAlert];
    }
}

- (void)onEditButtonPressed:(UIButton *)sender
{
    [self onLeftEditButtonPressed:sender.tag];
}

#pragma mark - OATableViewCellDelegate

- (void)onLeftEditButtonPressed:(NSInteger)tag
{
    _hasChangesBeenMade = YES;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag & 0x3FF inSection:tag >> 10];
    if (indexPath.section == kAllApplicationProfilesSection)
        [self deleteMode:indexPath];
    else
        [self restoreMode:indexPath];
}

@end
