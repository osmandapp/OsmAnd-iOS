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
#import "OAOsmNoteBottomSheetViewController.h"
#import "OAOsmEditingBottomSheetViewController.h"
#import "OAMultiselectableHeaderView.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"

typedef NS_ENUM(NSInteger, EOAEditsListType)
{
    EDITS_ALL = 0,
    EDITS_POI,
    EDITS_NOTES
};

@interface OAOsmEditsListViewController () <UITableViewDataSource, UITableViewDelegate, OAOsmEditingBottomSheetDelegate, OAMultiselectableHeaderDelegate>
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;

@end

@implementation OAOsmEditsListViewController
{
    EOAEditsListType _screenType;
    OAPOIHelper *_poiHelper;
    
    NSArray *_data;
    NSArray *_pendingNotes;
    
    OAMultiselectableHeaderView *_headerView;
    
    BOOL _popToParent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _poiHelper = [OAPOIHelper sharedInstance];
    [self applySafeAreaMargins];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    _headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 55.0)];
    _headerView.delegate = self;
    [self setupView];
    
    _tableView.estimatedRowHeight = kEstimatedRowHeight;
    _tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void) setShouldPopToParent:(BOOL)shouldPop
{
    _popToParent = shouldPop;
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
    [_segmentControl setTitle:OALocalizedString(@"shared_string_all") forSegmentAtIndex:0];
    [_segmentControl setTitle:OALocalizedString(@"osm_edits_edits_label") forSegmentAtIndex:1];
    [_segmentControl setTitle:OALocalizedString(@"osm_edits_notes") forSegmentAtIndex:2];
}

-(void)setupView
{
    [_headerView setTitleText:[self getLocalizedHeaderTitle]];
    NSMutableArray *dataArr = [NSMutableArray new];
    NSArray *poi = [[OAOsmEditsDBHelper sharedDatabase] getOpenstreetmapPoints];
    NSArray *notes = [[OAOsmBugsDBHelper sharedDatabase] getOsmBugsPoints];
    if (_screenType == EDITS_ALL || _screenType == EDITS_POI)
    {
        for (OAOpenStreetMapPoint *p in poi)
        {
            NSString *poiType = [p.getEntity getTagFromString:POI_TYPE_TAG];
            poiType = poiType ? [poiType lowerCase] : @"";
            NSString *name = p.getName;
            [dataArr addObject:@{
                                 @"title" : name.length == 0 ? [self getDescription:p] : name,
                                 @"poi_type" : poiType,
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
    NSString *actionStr = point.getLocalizedAction;
    NSString *type = [OAOsmEditingPlugin getCategory:point];
    NSMutableString *result = [NSMutableString new];
    [result appendString:actionStr];
    if (type)
    {
        [result appendString:@" • "];
        [result appendString:type];
    }
    if (point.getGroup == POI && point.getAction != CREATE)
    {
        [result appendString:@" • "];
        [result appendString:OALocalizedString(@"osm_poi_id_label")];
        [result appendString:@" "];
        [result appendString:[NSString stringWithFormat:@"%lld", point.getId]];
    }
    return result;
}

- (NSString *) getLocalizedHeaderTitle
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

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 55.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return _headerView;
    
    return nil;
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
    cell = (OAMultiIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:[OAMultiIconTextDescCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
        cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [cell.textView setText:item[@"title"]];
        [cell.descView setText:item[@"description"]];
        [cell.iconView setImage:poiType ? poiType.icon : [UIImage imageNamed:@"ic_custom_osm_note_unresolved"]];
        [cell.overflowButton setImage:[UIImage templateImageNamed:@"ic_custom_overflow_menu.png"] forState:UIControlStateNormal];
        [cell.overflowButton setTintColor:UIColorFromRGB(color_icon_color_light)];
        [cell.overflowButton setTag:indexPath.row];
        [cell.overflowButton removeTarget:NULL action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.overflowButton addTarget:self action:@selector(overflowButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [cell.overflowButton.imageView setContentMode:UIViewContentModeCenter];
        cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView.isEditing)
        return;
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
   if (_popToParent)
        [super backButtonClicked:sender];
    else
        [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)deleteButtonPressed:(id)sender {
    [self.tableView beginUpdates];
    BOOL shouldEdit = ![self.tableView isEditing];
    
    if (shouldEdit)
        [_uploadButton setHidden:YES];
    else
    {
        [_uploadButton setHidden:NO];
        NSArray *indexes = [self.tableView indexPathsForSelectedRows];
        if (indexes.count > 0)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:
                                        [NSString stringWithFormat:OALocalizedString(@"osm_confirm_bulk_delete"), indexes.count]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                for (NSIndexPath *path in indexes)
                {
                    NSDictionary *item = [self getItem:path];
                    OAOsmPoint *point = item[@"item"];
                    if (point)
                    {
                        if (point.getGroup == POI)
                            [[OAOsmEditsDBHelper sharedDatabase] deletePOI:(OAOpenStreetMapPoint *)point];
                        else
                            [[OAOsmBugsDBHelper sharedDatabase] deleteAllBugModifications:(OAOsmNotePoint *)point];
                    }
                }
                [self setupView];
                [self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
                [[OsmAndApp instance].osmEditsChangeObservable notifyEvent];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    [self.tableView setEditing:shouldEdit animated:YES];
    [self.tableView endUpdates];
}

- (IBAction)uploadButtonPressed:(id)sender {
    [self.tableView beginUpdates];
    BOOL shouldEdit = ![self.tableView isEditing];

    if (shouldEdit)
        [_deleteButton setHidden:YES];
    else
    {
        [_deleteButton setHidden:NO];
        NSArray *indexes = [self.tableView indexPathsForSelectedRows];
        NSMutableArray *edits = [NSMutableArray new];
        NSMutableArray *notes = [NSMutableArray new];
        
        for (NSIndexPath *indexPath in indexes)
        {
            OAOsmPoint *p = [self getItem:indexPath][@"item"];
            if (p.getGroup == POI)
                [edits addObject:p];
            else
                [notes addObject:p];
        }
        if (edits.count > 0)
        {
            OAOsmEditingBottomSheetViewController *editsBottomsheet = [[OAOsmEditingBottomSheetViewController alloc] initWithEditingUtils:((OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class]).getPoiModificationRemoteUtil points:edits];
            editsBottomsheet.delegate = self;
            _pendingNotes = notes;
            [editsBottomsheet show];
            
        }
        else if (notes.count > 0)
        {
            _pendingNotes = nil;
            OAOsmNoteBottomSheetViewController *notesBottomsheet = [[OAOsmNoteBottomSheetViewController alloc] initWithEditingPlugin:(OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class] points:notes type:TYPE_UPLOAD];
            notesBottomsheet.delegate = self;
            [notesBottomsheet show];
        }
    
    }
    [self.tableView setEditing:shouldEdit animated:YES];
    [self.tableView endUpdates];
}

-(void) overflowButtonPressed:(UIButton *)sender
{
    NSDictionary *item = [self getItem:[NSIndexPath indexPathForRow:sender.tag inSection:0]];
    OAOsmEditActionsViewController *bottomSheet = [[OAOsmEditActionsViewController alloc] initWithPoint:item[@"item"]];
    bottomSheet.delegate = self;
    [bottomSheet show];
}

#pragma mark - OAOsmEditingBottomSheetDelegate

-(void)refreshData
{
    [self setupView];
    [_tableView reloadData];
}

-(void)uploadFinished:(BOOL)hasError
{
    [self refreshData];
    if (_pendingNotes && _pendingNotes.count > 0 && !hasError)
    {
        OAOsmNoteBottomSheetViewController *notesBottomsheet = [[OAOsmNoteBottomSheetViewController alloc] initWithEditingPlugin:(OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class] points:_pendingNotes type:TYPE_UPLOAD];
        notesBottomsheet.delegate = self;
        [notesBottomsheet show];
    }
    _pendingNotes = nil;
}

#pragma mark - OAMultiselectableHeaderDelegate

-(void)headerCheckboxChanged:(id)sender value:(BOOL)value
{
    OAMultiselectableHeaderView *headerView = (OAMultiselectableHeaderView *)sender;
    NSInteger section = headerView.section;
    NSInteger rowsCount = [self.tableView numberOfRowsInSection:section];
    
    [self.tableView beginUpdates];
    if (value)
    {
        for (int i = 0; i < rowsCount; i++)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        for (int i = 0; i < rowsCount; i++)
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES];
    }
    [self.tableView endUpdates];
}

@end
