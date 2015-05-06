//
//  OASetParkingViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASetParkingViewController.h"
#import "Localization.h"
#import "OASwitchTableViewCell.h"
#import "OADateTimePickerTableViewCell.h"
#import "OATimeTableViewCell.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@interface OASetParkingViewController ()

@end

@implementation OASetParkingViewController
{
    OAMapViewController *_mapViewController;
    
    NSDateFormatter *_timeFmt;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    if (self) {
        _coord = coordinate;
        _timeLimitActive = NO;
        _addToCalActive = YES;
        _timeFmt = [[NSDateFormatter alloc] init];
        [_timeFmt setDateStyle:NSDateFormatterNoStyle];
        [_timeFmt setTimeStyle:NSDateFormatterShortStyle];
        _date = [NSDate dateWithTimeIntervalSinceNow:60 * 60];
    }
    return self;
}

- (void)viewWillLayoutSubviews
{
    [self updateLayout:self.interfaceOrientation];
}

- (void)updateLayout:(UIInterfaceOrientation)interfaceOrientation
{
    
    CGFloat big;
    CGFloat small;
    
    CGRect rect = self.view.bounds;
    if (rect.size.width > rect.size.height)
    {
        big = rect.size.width;
        small = rect.size.height;
    }
    else
    {
        big = rect.size.height;
        small = rect.size.width;
    }
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            CGFloat topY = 64.0;
            CGFloat mapHeight = big - topY;
            CGFloat mapWidth = small / 1.7;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.tableView.frame = CGRectMake(mapWidth, topY, small - mapWidth, big - topY);
        }
        else
        {
            CGFloat topY = 64.0;
            CGFloat mapWidth = small;
            CGFloat mapHeight = 150.0;
            CGFloat mapBottom = topY + mapHeight;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.tableView.frame = CGRectMake(0.0, mapBottom, small, big - mapBottom);
        }
    }
    else
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            CGFloat topY = 64.0;
            CGFloat mapHeight = small - topY;
            CGFloat mapWidth = big / 1.5;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.tableView.frame = CGRectMake(mapWidth, topY, big - mapWidth, small - topY);
        }
        else
        {
            CGFloat topY = 64.0;
            CGFloat mapHeight = small - topY;
            CGFloat mapWidth = big / 2.0;
            
            self.mapView.frame = CGRectMake(0.0, topY, mapWidth, mapHeight);
            self.tableView.frame = CGRectMake(mapWidth, topY, big - mapWidth, small - topY);
        }
    }
}

- (void)applyLocalization
{
    [_buttonCancel setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_buttonAdd setTitle:OALocalizedString(@"shared_string_add") forState:UIControlStateNormal];
    _titleView.text = OALocalizedString(@"parking_marker");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    
    Point31 point = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_coord.latitude, _coord.longitude))];
    
    [[OARootViewController instance].mapPanel prepareMapForReuse:point zoom:15.0 newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[OARootViewController instance].mapPanel doMapReuse:self destinationView:self.mapView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(IBAction)cancelPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)addPressed:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(addParkingPoint:)])
        [self.delegate addParkingPoint:self];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)timeLimitSwitched:(id)sender
{
    _timeLimitActive = ((UISwitch*)sender).isOn;
    [_tableView beginUpdates];
    
    NSArray *paths = @[
                       [NSIndexPath indexPathForRow:1 inSection:0],
                       [NSIndexPath indexPathForRow:2 inSection:0],
                       [NSIndexPath indexPathForRow:3 inSection:0]];
    
    if (_timeLimitActive)
        [_tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationBottom];
    else
        [_tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
    
    [_tableView endUpdates];
}

-(void)timePickerChanged:(id)sender
{
    UIDatePicker *picker = (UIDatePicker *)sender;
    _date = picker.date;
    if (_timeLimitActive)
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

-(void)addNotificationSwitched:(id)sender
{
    _addToCalActive = ((UISwitch*)sender).isOn;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"sett_settings");
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_timeLimitActive)
        return 4;
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* const reusableIdentifierSwitch = @"OASwitchTableViewCell";
    static NSString* const reusableIdentifierTimePicker = @"OADateTimePickerTableViewCell";
    static NSString* const reusableIdentifierTime = @"OATimeTableViewCell";
    
    switch (indexPath.row)
    {
        case 0:
        {
            OASwitchTableViewCell* cell;
            cell = (OASwitchTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierSwitch];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
                cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            }
            [cell.switchView setOn:_timeLimitActive];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(timeLimitSwitched:) forControlEvents:UIControlEventValueChanged];
            
            cell.textView.text = OALocalizedString(@"time_limited");
            
            return cell;
        }
        case 1:
        {
            OATimeTableViewCell* cell;
            cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierTime];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATimeCell" owner:self options:nil];
                cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.lbTitle.text = OALocalizedString(@"pickup_car_at");
            cell.lbTime.text = [_timeFmt stringFromDate:_date];
            
            return cell;
        }
        case 2:
        {
            OADateTimePickerTableViewCell* cell;
            cell = (OADateTimePickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierTimePicker];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADateTimePickerCell" owner:self options:nil];
                cell = (OADateTimePickerTableViewCell *)[nib objectAtIndex:0];
                cell.dateTimePicker.date = _date;
            }
            
            [cell.dateTimePicker removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.dateTimePicker addTarget:self action:@selector(timePickerChanged:) forControlEvents:UIControlEventValueChanged];
            
            return cell;
        }
        case 3:
        {
            OASwitchTableViewCell* cell;
            cell = (OASwitchTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierSwitch];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
                cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            }
            
            [cell.switchView setOn:_addToCalActive];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(addNotificationSwitched:) forControlEvents:UIControlEventValueChanged];
            
            cell.textView.text = OALocalizedString(@"add_notification_calendar");
            
            return cell;
        }
            
        default:
            break;
    }
    
    return nil;
}



#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 2)
        return 162.0;
    else
        return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}


@end
