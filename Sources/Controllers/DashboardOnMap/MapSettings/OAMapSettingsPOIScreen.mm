//
//  OAMapSettingsPOIScreen.m
//  OsmAnd
//
//  Created by Paul on 8/18/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMapSettingsPOIScreen.h"
#import "OAMapSettingsViewController.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAIconTextDescCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAIconButtonCell.h"
#import "OAPOIUIFilter.h"
#import "OAPOIFiltersHelper.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAQuickSearchTableController.h"

typedef NS_ENUM(NSInteger, EOAPoiRowType) {
    EOAPoiRowTypeButton,
    EOAPoiRowTypePoiFilter
};

@interface OAPOIFilterTableRow : NSObject

@property (nonatomic, readonly) UIImage *icon;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) EOAPoiRowType rowType;
@property (nonatomic, readonly) OAPOIUIFilter *filter;

- (instancetype) initWithRowType:(EOAPoiRowType)rowType icon:(UIImage *)icon title:(NSString *)title;
- (instancetype) initWithRowType:(EOAPoiRowType)rowType title:(NSString *)title poiFilter:(OAPOIUIFilter *)filter;

@end

@implementation OAPOIFilterTableRow

- (instancetype) initWithRowType:(EOAPoiRowType)rowType icon:(UIImage *)icon title:(NSString *)title
{
    self = [super init];
    if (self) {
        _rowType = rowType;
        _icon = icon;
        _title = title;
    }
    return self;
}

- (instancetype) initWithRowType:(EOAPoiRowType)rowType title:(NSString *)title poiFilter:(OAPOIUIFilter *)filter
{
    self = [self initWithRowType:rowType icon:nil title:title];
    if (self) {
        _filter = filter;
    }
    return self;
}

@end

@implementation OAMapSettingsPOIScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAPOIFiltersHelper *_poiFiltersHelper;
    
    NSMutableArray<OAPOIFilterTableRow *> *rows;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _poiFiltersHelper = [OAPOIFiltersHelper sharedInstance];
        settingsScreen = EMapSettingsScreenPOI;
        vwController = viewController;
        tblView = tableView;
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
}

- (void) deinit
{
}

- (void) initData
{
    rows = [NSMutableArray array];
    [rows addObject:[[OAPOIFilterTableRow alloc] initWithRowType:EOAPoiRowTypeButton icon:[UIImage imageNamed:@"icon_remove.png"] title:OALocalizedString(@"poi_clear")]];
    NSArray<OAPOIUIFilter *> *filters = [OAPOIFiltersHelper.sharedInstance getSortedPoiFilters:YES];
    for (OAPOIUIFilter *filter in filters)
    {
        if (!filter.isTopWikiFilter)
            [rows addObject:[[OAPOIFilterTableRow alloc] initWithRowType:EOAPoiRowTypePoiFilter title:filter.getName poiFilter:filter]];
    }
}

- (void) setupView
{
    title = OALocalizedString(@"poi_overlay");
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [rows count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAPOIFilterTableRow *item = [rows objectAtIndex:indexPath.row];
    if (item.rowType == EOAPoiRowTypeButton)
    {
        OAIconButtonCell* cell;
        cell = (OAIconButtonCell *)[tableView dequeueReusableCellWithIdentifier:[OAIconButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconButtonCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.contentView.backgroundColor = [UIColor whiteColor];
            cell.arrowIconView.hidden = YES;
            [cell setImage:item.icon tint:YES];
            if (item.title)
                [cell.textView setText:title];
            else
                [cell.textView setText:@""];
        }
        if ([cell needsUpdateConstraints])
            [cell updateConstraints];
        return cell;
    }
    else if (item.rowType == EOAPoiRowTypePoiFilter)
    {
        OAPOIUIFilter *filter = item.filter;
        NSString *name = item.title;
        UIImage *icon;
        NSObject *res = [filter getIconResource];
        if ([res isKindOfClass:[NSString class]])
        {
            NSString *iconName = (NSString *)res;
            icon = [OAUtilities getMxIcon:iconName];
        }
        if (!icon)
            icon = [OAUtilities getMxIcon:@"user_defined"];
        OAIconTextDescCell *cell = [OAQuickSearchTableController getIconTextDescCell:name tableView:self.tblView typeName:@"" icon:icon];
        [self prepareCell:cell uiFilter:filter];
        return cell;
    }
    return nil;
}

- (void) prepareCell:(OAIconTextDescCell *)cell uiFilter:(OAPOIUIFilter *)filter
{
    cell.arrowIconView.hidden = YES;
    if ([[[OAPOIFiltersHelper sharedInstance] getSelectedPoiFilters] containsObject:filter]) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        cell.accessoryView = imageView;
    }
    else {
        cell.accessoryView = nil;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) combineFilterWithselectedFilters:(NSMutableSet<OAPOIUIFilter *> *)selectedFilters uiFilter:(OAPOIUIFilter *)uiFilter {
    if ([selectedFilters containsObject:uiFilter]) {
        [selectedFilters removeObject:uiFilter];
        [_poiFiltersHelper removeSelectedPoiFilter:uiFilter];
    } else {
        if (uiFilter.isStandardFilter)
            [uiFilter removeUnsavedFilterByName];
        [selectedFilters addObject:uiFilter];
        [_poiFiltersHelper addSelectedPoiFilter:uiFilter];
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAPOIFilterTableRow *item = [rows objectAtIndex:indexPath.row];
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    if (item.rowType == EOAPoiRowTypeButton)
    {
        [_poiFiltersHelper clearSelectedPoiFilters:@[[[OAPOIFiltersHelper sharedInstance] getTopWikiPoiFilter]]];
    }
    else if (item.rowType == EOAPoiRowTypePoiFilter)
    {
        NSMutableSet<OAPOIUIFilter *> *selectedFilters = [[NSMutableSet alloc] initWithSet:[_poiFiltersHelper getSelectedPoiFilters]];
        OAPOIUIFilter *uiFilter = item.filter;
        [self combineFilterWithselectedFilters:selectedFilters uiFilter:uiFilter];
    }
    [mapVC updatePoiLayer];
    [tblView reloadData];
}
@end
