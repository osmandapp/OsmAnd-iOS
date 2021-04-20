//
//  OARearrangeCustomFiltersViewController.mm
//  OsmAnd
//
// Created by Skalii Dmitrii on 19.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OARearrangeCustomFiltersViewController.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "Localization.h"
#import "OADeleteButtonTableViewCell.h"
#import "OAColors.h"

#define kAllFiltersSection 0

@interface OAEditFilterItem : NSObject

@property (nonatomic) int order;
@property (nonatomic) OAPOIUIFilter *filter;

- (instancetype) initWithFilter:(OAPOIUIFilter *)filter;

@end

@implementation OAEditFilterItem

- (instancetype) initWithFilter:(OAPOIUIFilter *)filter
{
    self = [super init];
    if (self) {
        _filter = filter;
        _order = filter.order;
    }
    return self;
}

@end

@interface OARearrangeCustomFiltersViewController() <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OARearrangeCustomFiltersViewController
{
    NSMutableArray<OAEditFilterItem *> *_filters;
    NSMutableArray<OAEditFilterItem *> *_deletedFilters;

    BOOL _hasChangesBeenMade;
}

-(instancetype)initWithFilters:(NSArray<OAPOIUIFilter *> *)filters
{
    self = [super init];
    if (self)
    {
        [self generateData:filters];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setEditing:YES];
    [self.navigationController.interactivePopGestureRecognizer addTarget:self action:@selector(swipeToCloseRecognized:)];
}

- (void)applyLocalization
{
    self.titleView.text = OALocalizedString(@"rearrange_categories");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (UIView *) getTopView
{
    return _navBar;
}

- (void) generateData:(NSArray<OAPOIUIFilter *> *)filters
{
    _filters = [[NSMutableArray alloc] init];
    _deletedFilters = [[NSMutableArray alloc] init];

    for (OAPOIUIFilter *filter in filters)
    {
        [_filters addObject:[[OAEditFilterItem alloc] initWithFilter:filter]];
    }
}

- (OAEditFilterItem *) getItem:(NSIndexPath *)indexPath
{
    BOOL isAllFilters = indexPath.section == kAllFiltersSection;
    return isAllFilters ? _filters[indexPath.row] : _deletedFilters[indexPath.row];
}

- (void) actionButtonPressed:(UIButton *)sender
{
    _hasChangesBeenMade = YES;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    if (indexPath.section == kAllFiltersSection)
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
    OAEditFilterItem *filterItem = _filters[indexPath.row];
    [_filters removeObject:filterItem];
    [_deletedFilters addObject:filterItem];
    [self updateFiltersIndexes];
    NSIndexPath *targetPath = [NSIndexPath indexPathForRow:_deletedFilters.count - 1 inSection:1];
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
    OAEditFilterItem *filterItem = _deletedFilters[indexPath.row];
    int order = filterItem.order;
    order = order > _filters.count ? (int) _filters.count : order;
    NSIndexPath *targetPath = [NSIndexPath indexPathForRow:order inSection:kAllFiltersSection];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [_tableView reloadData];
    }];
    [_deletedFilters removeObjectAtIndex:indexPath.row];
    [_filters insertObject:filterItem atIndex:order];
    [_tableView beginUpdates];
    [_tableView moveRowAtIndexPath:indexPath toIndexPath:targetPath];
    [_tableView endUpdates];
    [CATransaction commit];
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

- (void) swipeToCloseRecognized:(UIGestureRecognizer *)recognizer
{
    if (_hasChangesBeenMade)
    {
        recognizer.enabled = NO;
        recognizer.enabled = YES;
        [self showChangesAlert];
    }
}

- (IBAction)onCancelButtonClicked:(id)sender
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

- (IBAction) onDoneButtonClicked:(id)sender
{

}

- (void)updateFiltersIndexes
{
    for (int i = 0; i < _filters.count; i++)
    {
        _filters[i].order = i;
    }
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    BOOL isAllFilters = indexPath.section == kAllFiltersSection;
    OAPOIUIFilter *filter = isAllFilters ? _filters[indexPath.row].filter : _deletedFilters[indexPath.row].filter;

    static NSString* const identifierCell = @"OADeleteButtonTableViewCell";
    OADeleteButtonTableViewCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADeleteButtonTableViewCell" owner:self options:nil];
        cell = (OADeleteButtonTableViewCell *)[nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsMake(0.0, 58.0, 0.0, 0.0);
    }
    if (cell)
    {
        cell.titleLabel.text = filter.name;
        UIImage *poiIcon = [UIImage templateImageNamed:filter.getIconId];
        cell.iconImageView.image = poiIcon ? poiIcon : [UIImage templateImageNamed:@"ic_custom_user"];
        NSString *imageName = isAllFilters ? @"ic_custom_delete" : @"ic_custom_undo_button";
        [cell.deleteButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [cell.deleteButton setUserInteractionEnabled:YES];
        cell.deleteButton.tag = indexPath.section << 10 | indexPath.row;
        [cell.deleteButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == kAllFiltersSection;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    _hasChangesBeenMade = YES;
    OAEditFilterItem *filterItem = [self getItem:sourceIndexPath];
    // Deferr the data update until the animation is complete
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [_tableView reloadData];
    }];
    [_filters removeObjectAtIndex:sourceIndexPath.row];
    [_filters insertObject:filterItem atIndex:destinationIndexPath.row];
    [self updateFiltersIndexes];
    [CATransaction commit];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == kAllFiltersSection ? OALocalizedString(@"visible_categories") : OALocalizedString(@"hidden_categories");
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kAllFiltersSection)
        return _filters.count;
    else
        return _deletedFilters.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == kAllFiltersSection;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView * headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor  = UIColorFromRGB(color_text_footer);
    }
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
    if (proposedDestinationIndexPath.section != kAllFiltersSection)
        return sourceIndexPath;
    return proposedDestinationIndexPath;
}

@end
