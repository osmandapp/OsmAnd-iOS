//
//  OADeleteWaypointsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 13.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OADeleteWaypointsViewController.h"
#import "OABaseTrackMenuHudViewController.h"
#import "OATrackMenuHudViewController.h"
#import "OARootViewController.h"
#import "OAPointTableViewCell.h"
#import "OAGpxWptItem.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAAutoObserverProxy.h"
#import "OAGPXDocumentPrimitives.h"

@interface OADeleteWaypointsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *selectAllButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation OADeleteWaypointsViewController
{
    OsmAndAppInstance _app;
    OAAutoObserverProxy *_locationServicesUpdateObserver;

    NSArray<OAGPXTableSectionData *> *_tableData;
    NSDictionary<NSString *, NSArray<OAGpxWptItem *> *> *_waypointGroups;
    NSMutableDictionary<NSString *, NSMutableArray<OAGpxWptItem *> *> *_selectedWaypointGroups;
    BOOL _isCurrentTrack;
    NSString *_gpxFilePath;
}

- (instancetype)initWithSectionsData:(NSArray<OAGPXTableSectionData *> *)sectionsData
                      waypointGroups:(NSDictionary *)waypointGroups
                      isCurrentTrack:(BOOL)isCurrentTrack
                         gpxFilePath:(NSString *)gpxFilePath
{
    self = [super init];
    if (self)
    {
        _tableData = sectionsData;
        _waypointGroups = waypointGroups;
        _isCurrentTrack = isCurrentTrack;
        _gpxFilePath = gpxFilePath;
        _app = [OsmAndApp instance];
        _selectedWaypointGroups = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.editing = YES;

    [self setupDeleteButtonView];
    [self updateDistanceAndDirection];
    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(updateDistanceAndDirection)
                                                                 andObserve:_app.locationServices.updateObserver];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (_locationServicesUpdateObserver)
    {
        [_locationServicesUpdateObserver detach];
        _locationServicesUpdateObserver = nil;
    }
}

- (void)applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"delete_waypoints");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.selectAllButton setTitle:OALocalizedString(@"select_all") forState:UIControlStateNormal];
    [self.deleteButton setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
}

- (void)updateDistanceAndDirection
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (OAGPXTableSectionData *sectionData in _tableData)
        {
            if (sectionData.updateData)
                sectionData.updateData();
        }
        [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)setupDeleteButtonView
{
    BOOL hasSelection = _selectedWaypointGroups.allKeys.count != 0;
    self.deleteButton.backgroundColor = hasSelection ? UIColorFromRGB(color_primary_red) : UIColorFromRGB(color_route_button_inactive);
    [self.deleteButton setTintColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [self.deleteButton setTitleColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
    [self.deleteButton setUserInteractionEnabled:hasSelection];
}

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    OAGpxWptItem *gpxWptItem = [self getGpxWptItem:indexPath];
    NSString *groupName = gpxWptItem.point.type;
    if (!groupName || groupName.length == 0)
        groupName = OALocalizedString(@"gpx_waypoints");
    NSMutableArray<OAGpxWptItem *> *waypoints = _selectedWaypointGroups[groupName];

     if (waypoints)
     {
         if ([waypoints containsObject:gpxWptItem])
             [waypoints removeObject:gpxWptItem];
         else
            [waypoints addObject:gpxWptItem];
     }
     else
     {
         waypoints = [@[gpxWptItem] mutableCopy];
     }
    _selectedWaypointGroups[groupName] = waypoints.count > 0 ? waypoints : nil;

     [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
     [self setupDeleteButtonView];
}

- (OAGpxWptItem *)getGpxWptItem:(NSIndexPath *)indexPath
{
    NSString *groupName = _tableData[indexPath.section].header;
    return _waypointGroups[groupName][indexPath.row];
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData[indexPath.section].cells[indexPath.row];
}

- (IBAction)onCancelButtonClicked:(id)sender
{

    if (self.trackMenuDelegate)
        [self.trackMenuDelegate refreshWaypoints:NO];

    [self dismissViewController];
}

- (IBAction)onSelectAllButtonClicked:(id)sender
{
    for (NSString *groupName in _waypointGroups.keyEnumerator)
    {
        _selectedWaypointGroups[groupName] = [_waypointGroups[groupName] mutableCopy];
    }

    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                        [self.tableView reloadData];
                    }
                    completion: nil];

    [self setupDeleteButtonView];
}

- (IBAction)onDeleteButtonClicked:(id)sender
{
    OsmAndAppInstance app = [OsmAndApp instance];
    if (_isCurrentTrack)
    {
        OASavingTrackHelper *savingHelper = [OASavingTrackHelper sharedInstance];
        for (NSString *groupName in _selectedWaypointGroups.keyEnumerator)
        {
            NSArray<OAGpxWptItem *> *waypoints = _selectedWaypointGroups[groupName];
            for (OAGpxWptItem *waypoint in waypoints)
            {
                [savingHelper deleteWpt:waypoint.point];
            }
        }
        [[app trackRecordingObservable] notifyEvent];
    }
    else
    {
        NSString *path = [app.gpxPath stringByAppendingPathComponent:_gpxFilePath];
        for (NSString *groupName in _selectedWaypointGroups.keyEnumerator)
        {
            NSArray<OAGpxWptItem *> *waypoints = _selectedWaypointGroups[groupName];
            [[OARootViewController instance].mapPanel.mapViewController deleteWpts:waypoints docPath:path];
        }
    }

    if (self.trackMenuDelegate)
        [self.trackMenuDelegate refreshWaypoints:YES];

    [self dismissViewController];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tableData[section].cells.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _tableData[section].header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    UITableViewCell *outCell = nil;
    if ([cellData.type isEqualToString:[OAPointTableViewCell getCellIdentifier]])
    {
        OAPointTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAPointTableViewCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 66., 0., 0.);
            cell.distanceView.textColor = UIColorFromRGB(color_active_light);

            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.05];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            [cell.titleView setText:cellData.values[@"string_value_title"]];
            [cell.titleIcon setImage:cellData.leftIcon];

            [cell.distanceView setText:cellData.values[@"string_value_distance"]];
            cell.directionImageView.transform =
                    CGAffineTransformMakeRotation([cellData.values[@"float_value_direction"] floatValue]);

            if (![cell.directionImageView.tintColor isEqual:UIColorFromRGB(color_active_light)])
            {
                cell.directionImageView.image = [UIImage templateImageNamed:@"ic_small_direction"];
                cell.directionImageView.tintColor = UIColorFromRGB(color_active_light);
            }
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGpxWptItem *gpxWptItem = [self getGpxWptItem:indexPath];
    NSString *groupName = gpxWptItem.point.type;
    if (!groupName || groupName.length == 0)
        groupName = OALocalizedString(@"gpx_waypoints");
    NSMutableArray<OAGpxWptItem *> *selectedWaypoints = _selectedWaypointGroups[groupName];
    BOOL selected = selectedWaypoints && [selectedWaypoints containsObject:gpxWptItem];
    [cell setSelected:selected animated:YES];
    if (selected)
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    else
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectDeselectItem:indexPath];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectDeselectItem:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

@end
