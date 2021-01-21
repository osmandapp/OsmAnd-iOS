//
//  OASaveTrackViewController.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 14.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASaveTrackViewController.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATextViewResizingCell.h"
#import "OASwitchTableViewCell.h"
#import "OASaveTrackBottomSheetViewController.h"
#import "OAGPXDatabase.h"
#import "OAMapLayers.h"
#import "OAMapRendererView.h"

#define kTextInputCell @"OATextViewResizingCell"
#define kRouteGroupsCell @""
#define kSwitchCell @"OASwitchTableViewCell"

@interface OASaveTrackViewController() <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@end

@implementation OASaveTrackViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    OAAppSettings *_settings;
    
    NSString *_fileName;
    BOOL _showSimplifiedButton;
    BOOL _simplifiedTrack;
    BOOL _showOnMap;
}

- (instancetype) initWithParams:(NSString *)fileName showOnMap:(BOOL)showOnMap simplifiedTrack:(BOOL)simplifiedTrack
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _fileName = fileName;
        _showSimplifiedButton = simplifiedTrack;
        _showOnMap = showOnMap;
        
        [self commonInit];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.cancelButton.layer.cornerRadius = 9.0;
    self.saveButton.layer.cornerRadius = 9.0;
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"save_new_track");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    
    [data addObject:@[
        @{
            @"type" : kTextInputCell,
            @"fileName" : _fileName,
            @"header" : OALocalizedString(@"fav_name"),
            @"key" : @"input_name",
        }
    ]];
    
//    [data addObject:@[
//        @{
//            @"type" : kRouteGroupsCell,
//            @"header" : OALocalizedString(@"fav_group"),
//            @"key" : @"route_groups",
//        }
//    ]];
    
    if (_showSimplifiedButton)
    {
        [data addObject:@[
            @{
                @"type" : kSwitchCell,
                @"title" : OALocalizedString(@"simplified_track"),
                @"value" : @(_simplifiedTrack),
                @"key" : @"simplified_track",
                @"footer" : OALocalizedString(@"simplified_track_description")
            }
        ]];
    }
    
    [data addObject:@[
        @{
            @"type" : kSwitchCell,
            @"title" : OALocalizedString(@"map_settings_show"),
            @"value" : @(_showOnMap),
            @"key" : @"map_settings_show"
        }
    ]];
    
    _data = data;
}

- (IBAction)cancelButtonPressed:(id)sender
{
    [self dismissViewController];
}

- (IBAction)saveButtonPressed:(id)sender
{
    OAGPX *track = [[OAGPX alloc] init];
    track.gpxFileName = _fileName;
    
    [self dismissViewControllerAnimated:NO completion:nil];
    OASaveTrackBottomSheetViewController *bottomSheet = [[OASaveTrackBottomSheetViewController alloc] initWithNewTrack:track];
    [bottomSheet presentInViewController:OARootViewController.instance.mapPanel.mapViewController];
}

- (NSString *) renameFile
{
    return nil;
}

- (BOOL) fileExists
{
    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    NSArray *gpxList = [NSMutableArray arrayWithArray:db.gpxList];
    for (OAGPX *gpx in gpxList)
    {
        if ([_fileName isEqualToString:gpx.gpxFileName])
            return YES;
    }
    return NO;
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kTextInputCell])
    {
        OATextViewResizingCell* cell = [tableView dequeueReusableCellWithIdentifier:kTextInputCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTextInputCell owner:self options:nil];
            cell = (OATextViewResizingCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        if (cell)
        {
            cell.inputField.text = item[@"fileName"];
            cell.inputField.delegate = self;
            cell.inputField.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
            cell.clearButton.tag = cell.inputField.tag;
            [cell.clearButton removeTarget:NULL action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        return cell;
    }
    else if ([cellType isEqualToString:kSwitchCell])
    {
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    
    return [[UITableViewCell alloc] init];
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *item = ((NSArray *)_data[section]).firstObject;
    
    return item[@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSDictionary *item = ((NSArray *)_data[section]).firstObject;
    
    return item[@"footer"];
}

-(void) clearButtonPressed:(UIButton *)sender
{
    _fileName = @"";
    
    UIButton *btn = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:btn.tag & 0x3FF inSection:btn.tag >> 10];
    
    [_tableView beginUpdates];
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]];
    if ([cell isKindOfClass:OATextViewResizingCell.class])
        ((OATextViewResizingCell *) cell).inputField.text = @"";
    [_tableView endUpdates];
}

- (void) applyParameter:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"simplified_track"])
    {
        
    }
    if ([key isEqualToString:@"map_settings_show"])
    {
        
    }
}

#pragma mark - UITextViewDelegate

- (void) textViewDidChange:(UITextView *)textView
{
    _fileName = textView.text;
    
    [textView sizeToFit];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

@end
