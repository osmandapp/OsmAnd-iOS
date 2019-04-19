//
//  OAOsmEditsListViewController.m
//  OsmAnd
//
//  Created by Paul on 4/17/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditsListViewController.h"
#import "OASizes.h"
#import "Localization.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmPoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAEntity.h"
#import "OAPOIHelper.h"
#import "OAPOIType.h"
#import "OAEditPOIData.h"
#import "OAMultiIconTextDescCell.h"
#import "OAColors.h"
#import "OARootViewController.h"
#import "OATargetPoint.h"
#import "OAOsmEditsLayer.h"
#import "OAOsmEditActionsViewController.h"
#import "OAMapLayers.h"

typedef NS_ENUM(NSInteger, EOAEditsListType)
{
    EDITS_ALL = 0,
    EDITS_POI,
    EDITS_NOTES
};

@interface OAOsmEditsListViewController () <UITableViewDataSource, UITableViewDelegate, OAOsmActionForwardingDelegate>
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *navBarView;

@end

@implementation OAOsmEditsListViewController
{
    EOAEditsListType _screenType;
    OAPOIHelper *_poiHelper;
    
    NSArray *_data;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _poiHelper = [OAPOIHelper sharedInstance];
    [self applySafeAreaMargins];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self setupView];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(CGFloat) getNavBarHeight
{
    return navBarWithSegmentControl;
}

-(void) applyLocalization
{
    _titleView.text = OALocalizedString(@"osm_edits_title");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_segmentControl setTitle:OALocalizedString(@"shared_string_all") forSegmentAtIndex:0];
    [_segmentControl setTitle:OALocalizedString(@"osm_edits_edits_label") forSegmentAtIndex:1];
    [_segmentControl setTitle:OALocalizedString(@"osm_edits_notes") forSegmentAtIndex:2];
}

-(void)setupView
{
    NSMutableArray *dataArr = [NSMutableArray new];
    NSArray *poi = [[OAOsmEditsDBHelper sharedDatabase] getOpenstreetmapPoints];
    NSArray *notes = [[OAOsmBugsDBHelper sharedDatabase] getOsmBugsPoints];
    if (_screenType == EDITS_ALL || _screenType == EDITS_POI)
    {
        for (OAOpenStreetMapPoint *p in poi)
        {
            [dataArr addObject:@{
                                 @"title" : p.getName,
                                 @"poi_type" : [[p.getEntity getTagFromString:POI_TYPE_TAG] lowerCase],
                                 @"description" : [self getDescription:p],
                                 @"item" : p
                                 }];
        }
    }
    if (_screenType == EDITS_ALL || _screenType == EDITS_NOTES)
    {
        for (OAOsmPoint *p in notes)
        {
            [dataArr addObject:@{
                                 @"title" : p.getName,
                                 @"description" : [self getDescription:p],
                                 @"item" : p
                                 }];
        }
    }
    _data = [NSArray arrayWithArray:dataArr];
}

-(NSString *)getDescription:(OAOsmPoint *)point
{
    NSString *actionStr;
    switch (point.getAction) {
        case MODIFY:
        {
            actionStr = OALocalizedString(@"osm_modified");
            break;
        }
        case DELETE:
        {
            actionStr = OALocalizedString(@"osm_deleted");
            break;
        }
        case CREATE:
        {
            actionStr = OALocalizedString(@"osm_created");
            break;
        }
        case REOPEN:
        {
            actionStr = OALocalizedString(@"osm_reopened");
            break;
        }
        default:
        {
            actionStr = @"";
            break;
        }
    }
    NSString *type = point.getGroup == BUG ? OALocalizedString(@"osm_note") :
        [((OAOpenStreetMapPoint *) point).getEntity getTagFromString:POI_TYPE_TAG];
    NSMutableString *result = [NSMutableString new];
    [result appendString:actionStr];
    [result appendString:@" • "];
    [result appendString:type];
    if (point.getGroup == POI && point.getAction != CREATE)
    {
        [result appendString:@" • "];
        [result appendString:OALocalizedString(@"osm_poi_id_label")];
        [result appendString:@" "];
        [result appendString:[NSString stringWithFormat:@"%lld", point.getId]];
    }
    return result;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (_screenType)
    {
        case EDITS_ALL:
            return OALocalizedString(@"osm_edits_all");
        case EDITS_POI:
            return OALocalizedString(@"osm_edits_poi");
        case EDITS_NOTES:
            return OALocalizedString(@"osm_edits_notes");
        default:
            return nil;
    }
}

-(NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSDictionary *translatedNames = [_poiHelper getAllTranslatedNames:NO];
    OAPOIType *poiType = translatedNames[item[@"poi_type"]];
    OAMultiIconTextDescCell* cell;
    cell = (OAMultiIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:@"OAMultiIconTextDescCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMultiIconTextDescCell" owner:self options:nil];
        cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [cell.textView setText:item[@"title"]];
        [cell.descView setText:item[@"description"]];
        [cell.iconView setImage:poiType ? poiType.icon : [UIImage imageNamed:@"ic_custom_osm_note_unresolved"]];
        [cell.overflowButton setImage:[[UIImage imageNamed:@"ic_custom_overflow_menu.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [cell.overflowButton setTintColor:UIColorFromRGB(color_icon_color_light)];
        [cell.overflowButton setTag:indexPath.row];
        [cell.overflowButton addTarget:self action:@selector(overflowButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    return [OAMultiIconTextDescCell getHeight:item[@"title"] value:item[@"description"] cellWidth:DeviceScreenWidth];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    OAOsmPoint *p = item[@"item"];
    [self.navigationController popToRootViewControllerAnimated:YES];
    if (p)
    {
        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
        OATargetPoint *newTarget = [mapPanel.mapViewController.mapLayers.osmEditsLayer getTargetPoint:p];
        newTarget.centerMap = YES;
        [mapPanel showContextMenu:newTarget];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (IBAction)onSegmentChanged:(id)sender {
    switch (_segmentControl.selectedSegmentIndex)
    {
        case 0:
        {
            if (_screenType != EDITS_ALL)
            {
                _screenType = EDITS_ALL;
                [self setupView];
                [_tableView reloadData];
                return;
            }
        }
        case 1:
        {
            if (_screenType != EDITS_POI)
            {
                _screenType = EDITS_POI;
                [self setupView];
                [_tableView reloadData];
                return;
            }
        }
        case 2:
        {
            if (_screenType != EDITS_NOTES)
            {
                _screenType = EDITS_NOTES;
                [self setupView];
                [_tableView reloadData];
                return;
            }
        }
    }
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void) overflowButtonPressed:(UIButton *)sender
{
    NSDictionary *item = [self getItem:[NSIndexPath indexPathForRow:sender.tag inSection:0]];
    OAOsmEditActionsViewController *bottomSheet = [[OAOsmEditActionsViewController alloc] initWithPoint:item[@"item"]];
    bottomSheet.delegate = self;
    [bottomSheet show];
}

#pragma mark - OAOsmActionForwardingDelegate

-(void)refreshData
{
    [self setupView];
    [_tableView reloadData];
}

@end
