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
#import "OACustomSelectionButtonCell.h"
#import "OAMenuSimpleCell.h"
#import "OASegmentedControllCell.h"
#import "OATableViewCustomHeaderView.h"

@interface OADownloadMultipleResourceViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

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
            if (![OsmAndApp instance].resourcesManager->isResourceInstalled(item.resourceId))
                [_selectedItems addObject:item];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.editing = !_isSingleSRTM;
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];

    [self updateDownloadButtonView];
}

- (void)applyLocalization
{
    self.titleLabel.text = _isSRTM ? OALocalizedString(@"srtm_unit_format") : OALocalizedString(@"welmode_download_maps");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (void)updateDownloadButtonView
{
    BOOL hasSelection = _selectedItems.count != 0;
    self.downloadButton.backgroundColor = hasSelection ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_route_button_inactive);
    [self.downloadButton setTintColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [self.downloadButton setTitleColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
    [self.downloadButton setUserInteractionEnabled:hasSelection];
    [self updateTextDownloadButton];
}

- (void)updateTextDownloadButton
{
    uint64_t sizePkgSum = 0;
    for (OAResourceItem *item in _selectedItems)
    {
        if ([item isKindOfClass:OARepositoryResourceItem.class])
            sizePkgSum += ((OARepositoryResourceItem *) item).resource->packageSize;
        else
            sizePkgSum += [OsmAndApp instance].resourcesManager->getResourceInRepository(item.resourceId)->packageSize;
    }

    [self.downloadButton setTitle:sizePkgSum != 0 ? [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"download"), [NSByteCountFormatter stringFromByteCount:sizePkgSum countStyle:NSByteCountFormatterCountStyleFile]] : OALocalizedString(@"download") forState:UIControlStateNormal];
}

- (NSString *)getTitleForSection:(NSInteger)section
{

    if (section == 0 && _isSRTM)
        return _isSingleSRTM ? OALocalizedString(@"srtm_download_single_help_message") : OALocalizedString(@"srtm_download_list_help_message");
    else if ((section == 0 && !_isSRTM) || (section == 1 && !_isSingleSRTM))
        return [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, _items.count] upperCase];

    return nil;
}

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    if (!_isSingleSRTM)
    {
        if (indexPath.row > 0)
        {
            [self.tableView beginUpdates];
            OAResourceItem *item = _items[indexPath.row - 1];
            if ([_selectedItems containsObject:item])
                [_selectedItems removeObject:item];
            else
                [_selectedItems addObject:item];
            [self.tableView endUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        }
        [self updateDownloadButtonView];
    }
}

- (void)selectDeselectGroup:(id)sender
{
    if (!_isSingleSRTM)
    {
        [self.tableView beginUpdates];
        BOOL shouldSelect = _selectedItems.count == 0;
        NSInteger section = _isSRTM ? 1 : 0;
        if (!shouldSelect)
            [_selectedItems removeAllObjects];
        else
            [_selectedItems addObjectsFromArray:_items];

        for (NSInteger i = 0; i < _items.count; i++)
        {
            if (shouldSelect)
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:NO scrollPosition:UITableViewScrollPositionNone];
            else
                [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:NO];
        }
        [self.tableView endUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationNone];
        [self updateDownloadButtonView];
    }
}

- (void)segmentChanged:(id)sender
{
    if (_isSRTM)
    {
        UISegmentedControl *segment = (UISegmentedControl *) sender;
        if (segment)
        {
            [self.tableView beginUpdates];
            _srtmfOn = segment.selectedSegmentIndex == 1;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
            [_items removeAllObjects];
            for (OAResourceItem *item in _multipleItem.items)
            {
                if (_srtmfOn && [OAResourceType isSRTMF:item])
                    [_items addObject:item];
                else if (!_srtmfOn && ![OAResourceType isSRTMF:item])
                    [_items addObject:item];
            }
            [_selectedItems removeAllObjects];
            for (OAResourceItem *item in _items)
            {
                if (![OsmAndApp instance].resourcesManager->isResourceInstalled(item.resourceId))
                    [_selectedItems addObject:item];
            }
            [self updateDownloadButtonView];
            [self.tableView endUpdates];
        }
    }
}

- (IBAction)onDownloadButtonPressed:(id)sender
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

- (IBAction)onCancelButtonPressed:(id)sender
{
    [self dismissViewController];

    if (self.delegate)
        [self.delegate clearMultipleResources];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _isSRTM ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isSRTM)
    {
        if (section == 0)
            return 1;
        else if (section == 1)
            return _isSingleSRTM ? 1 : _items.count + 1;
    }

    return _items.count + 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _isSingleSRTM ? NO : indexPath.row != 0;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString *cellType = _isSRTM && indexPath.section == 0 ? [OASegmentedControllCell getCellIdentifier] : indexPath.row == 0 && !_isSingleSRTM ? [OACustomSelectionButtonCell getCellIdentifier] : [OAMenuSimpleCell getCellIdentifier];
    if ([cellType isEqualToString:[OASegmentedControllCell getCellIdentifier]])
    {
        OASegmentedControllCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentedControllCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.backgroundColor = UIColor.clearColor;
            cell.segmentedControl.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.1];

            if (@available(iOS 13.0, *))
                cell.segmentedControl.selectedSegmentTintColor = UIColorFromRGB(color_primary_purple);
            else
                cell.segmentedControl.tintColor = UIColorFromRGB(color_primary_purple);

            UIFont *font = [UIFont systemFontOfSize:15. weight:UIFontWeightSemibold];
            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColor.whiteColor, NSFontAttributeName : font} forState:UIControlStateSelected];
            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColorFromRGB(color_primary_purple), NSFontAttributeName : font} forState:UIControlStateNormal];
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
    else if ([cellType isEqualToString:[OACustomSelectionButtonCell getCellIdentifier]])
    {
        OACustomSelectionButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellType owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 0.0);
        }
        if (cell)
        {
            NSString *selectionText = _selectedItems.count > 0 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"select_all");
            [cell.selectDeselectButton setTitle:selectionText forState:UIControlStateNormal];
            [cell.selectDeselectButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.selectDeselectButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];
            [cell.selectionButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.selectionButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];

            NSInteger selectedAmount = _selectedItems.count;
            if (selectedAmount > 0)
            {
                UIImage *selectionImage = selectedAmount < _items.count - 1 ? [UIImage imageNamed:@"ic_system_checkbox_indeterminate"] : [UIImage imageNamed:@"ic_system_checkbox_selected"];
                [cell.selectionButton setImage:selectionImage forState:UIControlStateNormal];
            }
            else
            {
                [cell.selectionButton setImage:nil forState:UIControlStateNormal];
            }
            return cell;
        }
    }
    else if ([cellType isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
    {
        OAMenuSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellType owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 65., 0., 0.);
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            cell.descriptionView.hidden = NO;
            cell.descriptionView.font = [UIFont systemFontOfSize:13.0];
            if (!_isSingleSRTM)
            {
                UIView *bgColorView = [[UIView alloc] init];
                bgColorView.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.05];
                [cell setSelectedBackgroundView:bgColorView];
            }
        }
        if (cell)
        {
            OAResourceItem *item = _items[!_isSingleSRTM ? indexPath.row - 1 : indexPath.row];
            BOOL selected = !_isSingleSRTM && [_selectedItems containsObject:item];

            cell.imgView.image = [OAResourceType getIcon:_type.type];
            cell.imgView.tintColor = selected ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_tint_gray);
            cell.imgView.contentMode = UIViewContentModeCenter;

            cell.textView.text = item.title;

            NSString *size;
            if ([item isKindOfClass:OARepositoryResourceItem.class])
                size = [NSByteCountFormatter stringFromByteCount:((OARepositoryResourceItem *) item).resource->packageSize countStyle:NSByteCountFormatterCountStyleFile];
            else
                size = [NSByteCountFormatter stringFromByteCount:[OsmAndApp instance].resourcesManager->getResourceInRepository(item.resourceId)->packageSize countStyle:NSByteCountFormatterCountStyleFile];

            if ([OAResourceType isSRTMResourceItem:item])
                size = [NSString stringWithFormat:@"%@ (%@)", size, [OAResourceType getSRTMFormatItem:item longFormat:NO]];

            cell.descriptionView.text = [NSString stringWithFormat:@"%@ • %@", size, [item getDate]];

            if ([cell needsUpdateConstraints])
                [cell updateConstraints];
            return cell;
        }
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_isSingleSRTM && indexPath.row > 0)
    {
        OAResourceItem *item = _items[indexPath.row - 1];
        BOOL selected = [_selectedItems containsObject:item];
        [cell setSelected:selected animated:NO];
        if (selected)
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_isSingleSRTM)
    {
        if (indexPath.row > 0)
            [self selectDeselectItem:indexPath];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_isSingleSRTM)
    {
        if (indexPath.row > 0)
            [self selectDeselectItem:indexPath];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    if (section == 0 && _isSRTM)
    {
        customHeader.label.text = [self getTitleForSection:section];
        customHeader.label.font = [UIFont systemFontOfSize:15];
        [customHeader setYOffset:12];
    }
    else if ((section == 0 && !_isSRTM) || (section == 1 && !_isSingleSRTM))
    {
        customHeader.label.text = [self getTitleForSection:section];
        customHeader.label.font = [UIFont systemFontOfSize:13];
        [customHeader setYOffset:_isSRTM ? 12 : 32];
    }
    return customHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0 && _isSRTM)
        return [OATableViewCustomHeaderView getHeight:[self getTitleForSection:section] width:tableView.bounds.size.width yOffset:12 font:[UIFont systemFontOfSize:15]] + 9;
    else if ((section == 0 && !_isSRTM) || (section == 1 && !_isSingleSRTM))
        return [OATableViewCustomHeaderView getHeight:[self getTitleForSection:section] width:tableView.bounds.size.width yOffset:_isSRTM ? 12 : 32 font:[UIFont systemFontOfSize:13]];

    return UITableViewAutomaticDimension;
}

@end
