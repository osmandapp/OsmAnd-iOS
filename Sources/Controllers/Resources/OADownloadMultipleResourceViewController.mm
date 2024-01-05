//
//  OADownloadMultipleResourceViewController.mm
//  OsmAnd
//
//  Created by Skalii on 15.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OADownloadMultipleResourceViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASimpleTableViewCell.h"
#import "OAButtonTableViewCell.h"
#import "OASegmentedControlCell.h"
#import "OADividerCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OADownloadMultipleResourceViewController () <OATableViewCellDelegate>

@end

@implementation OADownloadMultipleResourceViewController
{
    OAMultipleResourceItem *_multipleItem;
    NSMutableArray<OAResourceItem *> *_items;
    NSMutableArray<OAResourceItem *> *_selectedItems;
    OAResourceType *_type;
    BOOL _isSRTM;
    BOOL _isSingleSRTM;
    BOOL _srtmfOn;
}

#pragma mark - Initialization

- (instancetype)initWithResource:(OAMultipleResourceItem *)resource;
{
    self = [super init];
    if (self)
    {
        _multipleItem = resource;
        _type = [OAResourceType withType:resource.resourceType];
        _isSRTM = _type.type == OsmAndResourceType::SrtmMapRegion;
        _isSingleSRTM = [OAResourceType isSingleSRTMResourceItem:resource];
        if (_isSRTM)
        {
            _srtmfOn = [OAResourceType isSRTMFSettingOn];
            _items = [NSMutableArray new];
            for (OAResourceItem *item in resource.items)
            {
                if (_srtmfOn && [OAResourceType isSRTMF:item])
                    [_items addObject:item];
                else if (!_srtmfOn && ![OAResourceType isSRTMF:item])
                    [_items addObject:item];
            }
        }
        else
        {
            _items = [_multipleItem.items mutableCopy];
        }

        _selectedItems = [NSMutableArray new];
        for (OAResourceItem *item in _items)
        {
            if (!item.isInstalled)
                [_selectedItems addObject:item];
        }
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.editing = !_isSingleSRTM;
    self.tableView.allowsSelection = !_isSingleSRTM;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    [self updateBottomButtons];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _isSRTM ? OALocalizedString(@"srtm_unit_format") : OALocalizedString(@"welmode_download_maps");
}

- (NSString *)getTableHeaderDescription
{
    if (_isSRTM)
        return _isSingleSRTM ? OALocalizedString(@"srtm_download_single_help_message") : OALocalizedString(@"srtm_download_list_help_message");
    else return @"";
}

- (BOOL)hideFirstHeader
{
    return _isSRTM ? YES : NO;
}

- (NSString *)getTopButtonTitle
{
    uint64_t sizePkgSum = 0;
    for (OAResourceItem *item in _selectedItems)
    {
        if ([item isKindOfClass:OARepositoryResourceItem.class])
            sizePkgSum += ((OARepositoryResourceItem *) item).sizePkg;
        else
            sizePkgSum += [OsmAndApp instance].resourcesManager->getResourceInRepository(item.resourceId)->packageSize;
    }
    
    return sizePkgSum != 0 ? [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"shared_string_download"), [NSByteCountFormatter stringFromByteCount:sizePkgSum countStyle:NSByteCountFormatterCountStyleFile]] : OALocalizedString(@"shared_string_download");
}

- (NSString *)getBottomButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (EOABaseButtonColorScheme)getTopButtonColorScheme
{
    BOOL hasSelection = _selectedItems.count != 0;
    return hasSelection ? EOABaseButtonColorSchemePurple : EOABaseButtonColorSchemeInactive;
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return EOABaseButtonColorSchemeGraySimple;
}

#pragma mark - Table data

- (OAResourceItem *)getItem:(NSIndexPath * _Nonnull)indexPath
{
    OAResourceItem *item = _items[!_isSingleSRTM ? (indexPath.row - 1) / 2 - 1 : 0];
    return item;
}

- (NSInteger)sectionsCount
{
    return _isSRTM ? 2 : 1;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if ((section == 0 && !_isSRTM) || (section == 1 && !_isSingleSRTM))
        return [NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, _items.count];
    
    return nil;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (_isSRTM)
    {
        if (section == 0)
            return 1;
        else if (section == 1)
        {
            NSInteger count = _isSingleSRTM ? 3 : (_items.count + 1) * 2 + 1;
            return count;
        }
    }

    NSInteger count = (_items.count + 1) * 2 + 1;
    return count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    if ([self isDividerCell:indexPath])
    {
        OADividerCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *) nib[0];
            cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            cell.dividerColor = [UIColor colorNamed:ACColorNameCustomSeparator];
            cell.dividerHight = (1.0 / [UIScreen mainScreen].scale);
        }
        if (cell)
        {
            if (indexPath.row == 0 || indexPath.row == (_items.count + 1) * 2 || _isSingleSRTM)
                cell.dividerInsets = UIEdgeInsetsZero;
            else if (indexPath.row == 2)
                cell.dividerInsets = UIEdgeInsetsMake(0., 20., 0., 0.);
            else
                cell.dividerInsets = UIEdgeInsetsMake(0., [self tableView:self.tableView canEditRowAtIndexPath:indexPath] ? 110. : 70., 0., 0.);
        }
        return cell;
    }

    NSString *cellType = _isSRTM && indexPath.section == 0 ? [OASegmentedControlCell getCellIdentifier] :
    indexPath.row == 1 && !_isSingleSRTM ? [OAButtonTableViewCell getCellIdentifier] : [OASimpleTableViewCell getCellIdentifier];
    
    if ([cellType isEqualToString:[OASegmentedControlCell getCellIdentifier]])
    {
        OASegmentedControlCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellType];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentedControlCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.segmentedControl.backgroundColor = [[UIColor colorNamed:ACColorNameIconColorActive] colorWithAlphaComponent:.1];
            cell.segmentedControl.selectedSegmentTintColor = [UIColor colorNamed:ACColorNameIconColorActive];

            UIFont *font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameButtonTextColorPrimary], NSFontAttributeName : font} forState:UIControlStateSelected];
            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameButtonTextColorSecondary], NSFontAttributeName : font} forState:UIControlStateNormal];
        }
        if (cell)
        {
            [cell.segmentedControl setTitle:[[OAResourceType getSRTMFormatLong:NO] capitalizedString] forSegmentAtIndex:0];
            [cell.segmentedControl setTitle:[[OAResourceType getSRTMFormatLong:YES] capitalizedString] forSegmentAtIndex:1];
            [cell.segmentedControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.segmentedControl setSelectedSegmentIndex:_srtmfOn ? 1 : 0];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
    {
        OAButtonTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellType];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellType owner:self options:nil];
            cell = nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell descriptionVisibility:NO];
            [cell leftEditButtonVisibility:YES];
            cell.delegate = self;
            [cell.button.titleLabel setTextAlignment:NSTextAlignmentNatural];
            cell.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;

            UIButtonConfiguration *conf = [UIButtonConfiguration plainButtonConfiguration];
            conf.contentInsets = NSDirectionalEdgeInsetsMake(0., -6.5, 0., 0.);
            cell.leftEditButton.configuration = conf;
            cell.leftEditButton.layer.shadowColor = [UIColor colorNamed:ACColorNameIconColorDisabled].CGColor;
            cell.leftEditButton.layer.shadowOffset = CGSizeMake(0., 0.);
            cell.leftEditButton.layer.shadowOpacity = 1.;
            cell.leftEditButton.layer.shadowRadius = 1.;
        }
        if (cell)
        {
            NSUInteger selectedAmount = _selectedItems.count;
            NSString *selectionText = selectedAmount > 0 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"shared_string_select_all");
            [cell.button setTitle:selectionText forState:UIControlStateNormal];
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];

            UIImage *selectionImage = nil;
            if (selectedAmount > 0)
                selectionImage = [UIImage imageNamed:selectedAmount < _items.count ? @"ic_system_checkbox_indeterminate" : @"ic_system_checkbox_selected"];
            else
                selectionImage = [UIImage imageNamed:@"ic_custom_checkbox_unselected"];
            [cell.leftEditButton setImage:selectionImage forState:UIControlStateNormal];
            [cell.leftEditButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.leftEditButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellType];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellType owner:self options:nil];
            cell = nib[0];
            cell.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            if (!_isSingleSRTM)
            {
                UIView *bgColorView = [[UIView alloc] init];
                bgColorView.backgroundColor = [[UIColor colorNamed:ACColorNameIconColorActive] colorWithAlphaComponent:.05];
                [cell setSelectedBackgroundView:bgColorView];
            }
        }
        if (cell)
        {
            OAResourceItem * item = [self getItem:indexPath];
            BOOL selected = !_isSingleSRTM && [_selectedItems containsObject:item];
            BOOL installed = item.isInstalled;
            cell.leftIconView.image = [OAResourceType getIcon:_type.type templated:YES];
            cell.leftIconView.tintColor = selected ? [UIColor colorNamed:ACColorNameIconColorActive] :installed  ?  UIColorFromRGB( resource_installed_icon_color) : [UIColor colorNamed:ACColorNameIconColorDisabled];
            cell.leftIconView.contentMode = UIViewContentModeCenter;
            cell.accessoryType = installed ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryNone;
            cell.titleLabel.text = item.title;

            NSString *size;
            if ([item isKindOfClass:OARepositoryResourceItem.class])
                size = [NSByteCountFormatter stringFromByteCount:((OARepositoryResourceItem *) item).sizePkg countStyle:NSByteCountFormatterCountStyleFile];
            else
                size = [NSByteCountFormatter stringFromByteCount:[OsmAndApp instance].resourcesManager->getResourceInRepository(item.resourceId)->packageSize countStyle:NSByteCountFormatterCountStyleFile];

            if ([OAResourceType isSRTMResourceItem:item])
                size = [NSString stringWithFormat:@"%@ (%@)", size, [OAResourceType getSRTMFormatItem:item longFormat:NO]];

            cell.descriptionLabel.text = [NSString stringWithFormat:@"%@ • %@", size, [item getDate]];
            return cell;
        }
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (![self isDividerCell:indexPath] && indexPath.row > 2)
    {
        OAResourceItem * item = [self getItem:indexPath];
        if (!_isSingleSRTM && !item.isInstalled)
            [self selectDeselectItem:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath estimated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath estimated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_isSingleSRTM && ![self isDividerCell:indexPath] && indexPath.row > 2)
    {
        OAResourceItem *item = _items[(indexPath.row - 1) / 2 - 1];
        BOOL selected = [_selectedItems containsObject:item];
        [cell setSelected:selected animated:YES];
        if (selected)
            [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self isDividerCell:indexPath] && indexPath.row > 2)
    {
        if (!_isSingleSRTM)
            [self selectDeselectItem:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self dismissViewControllerAnimated:YES completion:^{
        OAResourceItem *item = [self getItem:indexPath];
        if ([item isKindOfClass:OALocalResourceItem.class])
            [self.delegate onDetailsSelected:(OALocalResourceItem *)item];
    }];
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _isSingleSRTM ? NO : (![self isDividerCell:indexPath] && indexPath.row > 2 && ![self isItemInstalled:indexPath]);
}

#pragma mark - Additions

- (BOOL)isItemInstalled:(NSIndexPath *)indexPath
{
    OAResourceItem *item = [self getItem:indexPath];
    return item && [item isInstalled];
}

- (BOOL)isDividerCell:(NSIndexPath *)indexPath
{
    BOOL isDividerCell = ((_isSRTM && indexPath.section == 1) || !_isSRTM) && indexPath.row % 2 == 0;
    return isDividerCell;
}

- (CGFloat)heightForRow:(NSIndexPath *)indexPath estimated:(BOOL)estimated
{
    if ([self isDividerCell:indexPath])
        return [OADividerCell cellHeight:(1.0 / [UIScreen mainScreen].scale) dividerInsets:UIEdgeInsetsZero];
    else if (_isSRTM && indexPath.section == 0)
        return 36.;
    else if (indexPath.row == 1 && ((_isSRTM && indexPath.section == 1 && !_isSingleSRTM) || (!_isSRTM && indexPath.section == 0)))
        return 48.;
    else
        return estimated ? 66. : UITableViewAutomaticDimension;
}

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    OAResourceItem *item = _items[(indexPath.row - 1) / 2 - 1];
    if ([_selectedItems containsObject:item])
        [_selectedItems removeObject:item];
    else
        [_selectedItems addObject:item];
    
    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                    animations:^(void)
     {
        [self.tableView reloadData];
    }
                    completion:nil];
    [self updateBottomButtons];
}

#pragma mark - Selectors

- (void)selectDeselectGroup:(UIButton *)sender
{
    [self onLeftEditButtonPressed:sender.tag];
}

- (void)segmentChanged:(id)sender
{
    if (_isSRTM)
    {
        UISegmentedControl *segment = (UISegmentedControl *) sender;
        if (segment)
        {
            _srtmfOn = segment.selectedSegmentIndex == 1;
            [_items removeAllObjects];
            for (OAResourceItem *item in _multipleItem.items)
            {
                if (_srtmfOn && [OAResourceType isSRTMF:item])
                    [_items addObject:item];
                else if (!_srtmfOn && ![OAResourceType isSRTMF:item])
                    [_items addObject:item];
            }
            
            NSMutableArray *newSelectedItems = [NSMutableArray new];
            for (OAResourceItem *item in _items)
            {
                if ([OsmAndApp instance].resourcesManager->isResourceInstalled(item.resourceId))
                    continue;
                
                for (OAResourceItem *selectedItem in _selectedItems)
                {
                    if ([item.title isEqualToString:selectedItem.title])
                    {
                        [newSelectedItems addObject:item];
                        break;
                    }
                }
            }
            _selectedItems = newSelectedItems;
            
            [UIView transitionWithView:self.tableView
                              duration:0.35f
                               options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                            animations:^(void)
             {
                [self.tableView reloadData];
            }
                            completion:nil];
            [self updateBottomButtons];
        }
    }
}

- (void)onTopButtonPressed
{
    [self dismissViewController];
    
    if (self.delegate)
    {
        if (_isSRTM)
        {
            NSMutableArray<OAResourceItem *> *itemsToCheck = [NSMutableArray new];
            for (OAResourceItem *selectedItem in _selectedItems)
            {
                QString srtmMapName = selectedItem.resourceId.remove(QLatin1String([OAResourceType isSRTMF:selectedItem] ? ".srtmf.obf" : ".srtm.obf"));
                for (OAResourceItem *itemToCheck in _multipleItem.items)
                {
                    if (itemToCheck.resourceId.startsWith(srtmMapName))
                        [itemsToCheck addObject:itemToCheck];
                }
            }
            [self.delegate checkAndDeleteOtherSRTMResources:itemsToCheck];
        }
        [self.delegate downloadResources:_multipleItem selectedItems:_selectedItems];
    }
}

- (void)onBottomButtonPressed
{
    [self dismissViewController];
    
    if (self.delegate)
        [self.delegate clearMultipleResources];
}

#pragma mark - OATableViewCellDelegate

- (void)onLeftEditButtonPressed:(NSInteger)tag
{
    if (!_isSingleSRTM)
    {
        BOOL shouldSelect = _selectedItems.count == 0;
        NSInteger section = _isSRTM ? 1 : 0;
        if (!shouldSelect)
        {
            [_selectedItems removeAllObjects];
        }
        else
        {
            [_items enumerateObjectsUsingBlock:^(OAResourceItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![obj isInstalled])
                    [_selectedItems addObject:obj];
            }];
        }

        for (NSInteger i = 1; i < _items.count + 1; i++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(i + 1) * 2 - 1 inSection:section];
            if (shouldSelect && ![_items[i - 1] isInstalled])
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            else
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        [UIView transitionWithView:self.tableView
                          duration:0.35f
                           options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                        animations:^(void)
                        {
                            [self.tableView reloadData];
                        }
                        completion:nil];
        [self updateBottomButtons];
    }
}

@end
