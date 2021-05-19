//
//  OAMapSettingsPOIScreen.m
//  OsmAnd
//
//  Created by Paul on 8/18/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMapSettingsPOIScreen.h"
#import "OAMapSettingsViewController.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OAQuickSearchListItem.h"
#import "Localization.h"
#import "OACustomSearchPoiFilter.h"
#import "OAUtilities.h"
#import "OAIconTextDescCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAQuickSearchButtonListItem.h"
#import "OAIconButtonCell.h"
#import "OAPOIUIFilter.h"
#import "OAPOIFiltersHelper.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAQuickSearchTableController.h"

@implementation OAMapSettingsPOIScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    NSMutableArray<OAQuickSearchListItem *> *rows;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
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
    OASearchResultCollection *res = [[[OAQuickSearchHelper instance] getCore] shallowSearch:[OASearchAmenityTypesAPI class] text:@"" matcher:nil];
    rows = [NSMutableArray array];
    [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:@"icon_remove.png"] text:OALocalizedString(@"poi_clear") onClickFunction:nil]];
    if (res)
    {
        for (OASearchResult *sr in [res getCurrentSearchResults])
            [rows addObject:[[OAQuickSearchListItem alloc] initWithSearchResult:sr]];
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
    OAQuickSearchListItem *item = [rows objectAtIndex:indexPath.row];
    OASearchResult *res = [item getSearchResult];
    if (res)
    {
        if (res.objectType == POI_TYPE)
        {
            if ([res.object isKindOfClass:[OAPOIUIFilter class]])
            {
                OAPOIUIFilter *filter = (OAPOIUIFilter *) res.object;
                NSString *name = [item getName];
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
            else if ([res.object isKindOfClass:[OAPOIFilter class]])
            {
                NSString *name = [item getName];
                NSString *typeName = [OAQuickSearchTableController applySynonyms:res];
                UIImage *icon = [((OAPOIFilter *)res.object) icon];
                OAIconTextDescCell *cell = [OAQuickSearchTableController getIconTextDescCell:name tableView:self.tblView typeName:typeName icon:icon];
                OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithBasePoiType:(OAPOIFilter *)res.object idSuffix:@""];
                [self prepareCell:cell uiFilter:filter];
                if ([cell needsUpdateConstraints])
                    [cell setNeedsUpdateConstraints];
                
                return cell;
            }
            else if ([res.object isKindOfClass:[OAPOICategory class]])
            {
                OAIconTextTableViewCell* cell;
                cell = (OAIconTextTableViewCell *)[tblView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
                if (cell == nil)
                {
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
                    cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                    cell.textView.numberOfLines = 0;
                }
                
                if (cell)
                {
                    cell.contentView.backgroundColor = [UIColor whiteColor];
                    cell.arrowIconView.hidden = YES;
                    [cell.textView setTextColor:[UIColor blackColor]];
                    [cell.textView setText:[item getName]];
                    [cell.iconView setImage:[((OAPOICategory *)res.object) icon]];
                }
                OAPOIUIFilter *uiFilter = [[OAPOIUIFilter alloc] initWithBasePoiType:(OAPOICategory *)res.object idSuffix:@""];
                if ([[[OAPOIFiltersHelper sharedInstance] getSelectedPoiFilters] containsObject:uiFilter]) {
                    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
                    cell.accessoryView = imageView;
                }
                else {
                    cell.accessoryView = nil;
                }
                return cell;
            }
            else if ([res.object isKindOfClass:[OAPOIType class]])
            {
                NSString *name = [item getName];
                NSString *typeName = [OAQuickSearchTableController applySynonyms:res];
                UIImage *icon = [((OAPOIType *)res.object) icon];
                OAIconTextDescCell *cell = [OAQuickSearchTableController getIconTextDescCell:name tableView:self.tblView typeName:typeName icon:icon];
                OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithBasePoiType:(OAPOIFilter *)res.object idSuffix:@""];
                [self prepareCell:cell uiFilter:filter];
                if ([cell needsUpdateConstraints])
                    [cell setNeedsUpdateConstraints];
                
                return cell;
            }
        }
    }
    else
    {
        if ([item getType] == BUTTON)
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
                OAQuickSearchButtonListItem *buttonItem = (OAQuickSearchButtonListItem *) item;
                cell.contentView.backgroundColor = [UIColor whiteColor];
                cell.arrowIconView.hidden = YES;
                [cell setImage:buttonItem.icon tint:YES];
                if ([buttonItem getName])
                    [cell.textView setText:[item getName]];
                else if ([buttonItem getAttributedName])
                    [cell.textView setAttributedText:[buttonItem getAttributedName]];
                else
                    [cell.textView setText:@""];
            }
            if ([cell needsUpdateConstraints])
                [cell updateConstraints];
            return cell;
        }
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

- (OAPOIUIFilter *) getFilter:(OAPOIUIFilter *)filter helper:(OAPOIFiltersHelper *)helper selectedFilters:(NSMutableSet<OAPOIUIFilter *> *)selectedFilters uiFilter:(OAPOIUIFilter *)uiFilter {
    if ([selectedFilters containsObject:uiFilter]) {
        [selectedFilters removeObject:uiFilter];
        [helper removeSelectedPoiFilter:uiFilter];
    } else {
        [selectedFilters addObject:uiFilter];
        [helper addSelectedPoiFilter:uiFilter];
    }
    return [helper combineSelectedFilters:selectedFilters];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAQuickSearchListItem *item = [rows objectAtIndex:indexPath.row];
    OASearchResult *res = [item getSearchResult];
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OAPOIFiltersHelper *helper = [OAPOIFiltersHelper sharedInstance];
    if (res.objectType == POI_TYPE)
    {
        NSMutableSet<OAPOIUIFilter *> *selectedFilters = [[NSMutableSet alloc] initWithSet:[helper getSelectedPoiFilters]];
        OAPOIUIFilter *filter;
        if ([res.object isKindOfClass:[OAPOIUIFilter class]])
        {
            OAPOIUIFilter *uiFilter = (OAPOIUIFilter *) res.object;
            filter = [self getFilter:filter helper:helper selectedFilters:selectedFilters uiFilter:uiFilter];
        }
        else if ([res.object isKindOfClass:[OAPOIFilter class]])
        {
            OAPOIFilter *poiFilter = (OAPOIFilter *) res.object;
            OAPOIUIFilter *uiFilter = [[OAPOIUIFilter alloc] initWithBasePoiType:poiFilter idSuffix:@""];
            filter = [self getFilter:filter helper:helper selectedFilters:selectedFilters uiFilter:uiFilter];
        }
        else if ([res.object isKindOfClass:[OAPOICategory class]])
        {
            OAPOICategory *poiCategory = (OAPOICategory *) res.object;
            OAPOIUIFilter *uiFilter = [[OAPOIUIFilter alloc] initWithBasePoiType:poiCategory idSuffix:@""];
            filter = [self getFilter:filter helper:helper selectedFilters:selectedFilters uiFilter:uiFilter];
        }
        else if ([res.object isKindOfClass:[OAPOIType class]])
        {
            OAPOIType *poiType = (OAPOIType *) res.object;
            OAPOIUIFilter *uiFilter = [[OAPOIUIFilter alloc] initWithBasePoiType:poiType idSuffix:@""];
            filter = [self getFilter:filter helper:helper selectedFilters:selectedFilters uiFilter:uiFilter];
        }
    } else if ([item getType] == BUTTON) {
        [helper clearSelectedPoiFilters];
    }
    [mapVC updatePoiLayer];
    [tblView reloadData];
}
@end
