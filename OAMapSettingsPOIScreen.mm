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
#import "OAQuickSearchButtonListItem.h"
#import "OAPOIType.h"
#import "OACustomSearchPoiFilter.h"
#import "OAUtilities.h"
#import "OAIconTextDescCell.h"
#import "OANameStringMatcher.h"
#import "OAIconTextTableViewCell.h"
#import "OASearchPhrase.h"
#import "OAQuickSearchButtonListItem.h"
#import "OAIconButtonCell.h"
#import "OAPOIUIFilter.h"
#import "OAPOIFiltersHelper.h"
#import "OASearchWord.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"

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
//    if ([visible containsObject:item.gpxFileName])
//        [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
//    else
//        [cell.iconView setImage:nil];
    if (res)
    {
        if (res.objectType == POI_TYPE)
        {
            if ([res.object isKindOfClass:[OACustomSearchPoiFilter class]])
            {
                OACustomSearchPoiFilter *filter = (OACustomSearchPoiFilter *) res.object;
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
                
                return [self getIconTextDescCell:name typeName:@"" icon:icon];
            }
            else if ([res.object isKindOfClass:[OAPOIFilter class]])
            {
                NSString *name = [item getName];
                NSString *typeName = [self applySynonyms:res];
                UIImage *icon = [((OAPOIFilter *)res.object) icon];
                
                return [self getIconTextDescCell:name typeName:typeName icon:icon];
            }
            else if ([res.object isKindOfClass:[OAPOICategory class]])
            {
                OAIconTextTableViewCell* cell;
                cell = (OAIconTextTableViewCell *)[tblView dequeueReusableCellWithIdentifier:@"OAIconTextTableViewCell"];
                if (cell == nil)
                {
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
                    cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                    cell.textView.numberOfLines = 0;
                    CGRect f = cell.textView.frame;
                    f.origin.y = 0.0;
                    f.size.height = cell.frame.size.height;
                    cell.textView.frame = f;
                    cell.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
                }
                
                if (cell)
                {
                    cell.contentView.backgroundColor = [UIColor whiteColor];
                    cell.arrowIconView.hidden = YES;
                    [cell.textView setTextColor:[UIColor blackColor]];
                    [cell.textView setText:[item getName]];
                    [cell.iconView setImage:[((OAPOICategory *)res.object) icon]];
                }
                return cell;
            }
        }
    }
    else
    {
        if ([item getType] == BUTTON)
        {
            OAIconButtonCell* cell;
            cell = (OAIconButtonCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconButtonCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconButtonCell" owner:self options:nil];
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
            return cell;
        }
    }
    return nil;
}

- (NSString *) applySynonyms:(OASearchResult *)res
{
    NSString *typeName = [OAQuickSearchListItem getTypeName:res];
    OAPOIBaseType *basePoiType = (OAPOIBaseType *)res.object;
    NSArray<NSString *> *synonyms = [basePoiType.nameSynonyms componentsSeparatedByString:@";"];
    OANameStringMatcher *nm = [res.requiredSearchPhrase getNameStringMatcher];
    if (![res.requiredSearchPhrase isEmpty] && ![nm matches:basePoiType.nameLocalized])
    {
        if ([nm matches:basePoiType.nameLocalizedEN])
        {
            typeName = [NSString stringWithFormat:@"%@ (%@)", typeName, basePoiType.nameLocalizedEN];
        }
        else
        {
            for (NSString *syn in synonyms)
            {
                if ([nm matches:syn])
                {
                    typeName = [NSString stringWithFormat:@"%@ (%@)", typeName, syn];
                    break;
                }
            }
        }
    }
    return typeName;
}

- (OAIconTextDescCell *) getIconTextDescCell:(NSString *)name typeName:(NSString *)typeName icon:(UIImage *)icon
{
    OAIconTextDescCell* cell;
    cell = (OAIconTextDescCell *)[self.tblView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
        cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
        cell.textView.numberOfLines = 0;
        cell.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    
    if (cell)
    {
        CGRect f = cell.textView.frame;
        if (typeName.length == 0)
        {
            f.origin.y = 0.0;
            f.size.height = cell.frame.size.height;
        }
        else
        {
            f.origin.y = 8.0;
            f.size.height = cell.frame.size.height - 30.0;
        }
        cell.textView.frame = f;
        cell.arrowIconView.hidden = YES;
        [cell.textView setText:name];
        [cell.descView setText:typeName];
        [cell.iconView setImage:icon];
    }
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAQuickSearchListItem *item = [rows objectAtIndex:indexPath.row];
    OASearchResult *res = [item getSearchResult];
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    if (res.objectType == POI_TYPE)
    {
        OAPOIUIFilter *filter = [[[OAPOIFiltersHelper sharedInstance] getSelectedPoiFilters] count] == 0 ? nil : [[[[OAPOIFiltersHelper sharedInstance] getSelectedPoiFilters] allObjects] objectAtIndex:0];
        if ([res.object isKindOfClass:[OACustomSearchPoiFilter class]])
        {
            OACustomSearchPoiFilter *customFilter = (OACustomSearchPoiFilter *) res.object;
            OAPOIUIFilter *customUIFilter = [[OAPOIUIFilter alloc] initWithName:[customFilter getName] filterId:CUSTOM_FILTER_ID acceptedTypes:[customFilter getAcceptedTypes]];
            if (filter == nil) {
                filter = customUIFilter;
            } else {
                [filter combineWithPoiFilter:customUIFilter];
            }
        }
        else if ([res.object isKindOfClass:[OAPOIFilter class]])
        {
            OAPOIFilter *poiFilter = (OAPOIFilter *) res.object;
            if (filter == nil) {
                filter = [[OAPOIUIFilter alloc] initWithBasePoiType:poiFilter idSuffix:@""];
            } else {
                [filter combineWithPoiFilter:[[OAPOIUIFilter alloc] initWithBasePoiType:poiFilter idSuffix:@""]];
            }
        }
        else if ([res.object isKindOfClass:[OAPOICategory class]])
        {
            OAPOICategory *poiCategory = (OAPOICategory *) res.object;
            [filter setTypeToAccept:poiCategory b:true];
            if (filter == nil) {
                filter = [[OAPOIUIFilter alloc] initWithBasePoiType:poiCategory idSuffix:@""];
            } else {
                [filter combineWithPoiFilter:[[OAPOIUIFilter alloc] initWithBasePoiType:poiCategory idSuffix:@""]];
            }
        }
        if (filter) {
            [[OAPOIFiltersHelper sharedInstance] clearSelectedPoiFilters];
            [[OAPOIFiltersHelper sharedInstance] addSelectedPoiFilter:filter];
            [mapVC showPoiOnMap:filter keyword:filter.filterId];
        }
    } else if ([item getType] == BUTTON) {
        [[OAPOIFiltersHelper sharedInstance] clearSelectedPoiFilters];
        [mapVC hidePoi];
    }
    [tblView reloadData];
}
@end
