//
//  OADownloadMapViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADownloadMapViewController.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OsmAndApp.h"
#import "OASelectMapSourceViewController.h"
#import "OAMapRendererView.h"

#include "Localization.h"
#include "OASizes.h"

#import "OAMenuSimpleCell.h"
#import "OASettingsTableViewCell.h"
#import "OATimeTableViewCell.h"
#import "OAPreviewZoomLevelsCell.h"
#import "OACustomPickerTableViewCell.h"

#define kCellTypeZoom @"time_cell"
#define kCellTypePicker @"picker"
#define kMinAllowedZoom 1
#define kMaxAllowedZoom 22
#define kZoomSection 1

@interface OADownloadMapViewController() <UITableViewDelegate, UITableViewDataSource, OACustomPickerTableViewCellDelegate, OAMapSourceSelectionDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;

@end

@implementation OADownloadMapViewController
{
    OsmAndAppInstance _app;
    NSDictionary *_data;
    
    NSInteger _minZoom;
    NSInteger _maxZoom;
    NSArray<NSDictionary *> *_zoomArray;
    NSArray<NSString *> *_possibleZoomValues;
    NSIndexPath *_pickerIndexPath;
    CALayer *_horizontalLine;
}

- (UIView *) getMiddleView
{
    return self.contentView;
}

- (CGFloat) getNavBarHeight
{
    return defaultNavBarHeight;
}

- (BOOL) supportMapInteraction
{
    return YES;
}

- (BOOL) supportFullScreen
{
    return NO;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (UIView *) getBottomView
{
    return self.bottomToolBarView;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (BOOL) disableScroll
{
    return YES;
}

- (BOOL) hasBottomToolbar
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFixed;
}

- (BOOL) isLandscape
{
    return (OAUtilities.isLandscape || OAUtilities.isIPad) && !OAUtilities.isWindowed;;
}

- (CGFloat) contentHeight
{
    return DeviceScreenHeight * kOATargetPointViewFullHeightKoef;
}

- (void) applyLocalization
{
    [self setTitle:OALocalizedString(@"download_map")];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.downloadButton setTitle:OALocalizedString(@"download") forState:UIControlStateNormal];
}

- (NSAttributedString *) getAttributedTypeStr
{
    return nil;
}

- (NSString *) getTypeStr
{
    return nil;
}

- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        _app = [OsmAndApp instance];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.bottomToolBarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.bottomToolBarView.layer addSublayer:_horizontalLine];
    [self updateToolBar];
    
    _cancelButton.layer.cornerRadius = 9.0;
    _downloadButton.layer.cornerRadius = 9.0;

    // to delete/change
    _possibleZoomValues = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20", @"21", @"22"];
    _minZoom = 8;
    _maxZoom = 16;
    
    [self setupView];
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *mapTypeArr = [NSMutableArray array];
    NSMutableArray *zoomLevelArr = [NSMutableArray array];
    NSMutableArray *generalInfoArr = [NSMutableArray array];
    
    NSString *mapSourceName;
    mapSourceName = _app.data.lastMapSource.name;
    
    [mapTypeArr addObject:@{
        @"type" : @"OASettingsTableViewCell",
        @"title" : OALocalizedString(@"map_settings_type"),
        @"value" : mapSourceName,
    }];
    
    [zoomLevelArr addObject:@{
        @"type" : @"OAPreviewZoomLevelsCell",
        @"value" : OALocalizedString(@"preview_of_selected_zoom_levels"),
    }];
    
    [zoomLevelArr addObject:@{
        @"title" : OALocalizedString(@"rec_interval_minimum"),
        @"value" : [NSString stringWithFormat:@"%ld", _minZoom],
        @"type"  : kCellTypeZoom,
        @"clickable" : @YES
    }];
    [zoomLevelArr addObject:@{
        @"title" : OALocalizedString(@"shared_string_maximum"),
        @"value" : [NSString stringWithFormat:@"%ld", _maxZoom],
        @"type" : kCellTypeZoom,
        @"clickable" : @YES
    }];
    [zoomLevelArr addObject:@{
        @"type" : kCellTypePicker,
    }];
    
    [generalInfoArr addObject:@{
        @"type" : kCellTypeZoom,
        @"title" : OALocalizedString(@"number_of_tiles"),
        @"value" : @"120 700", // change
        @"clickable" : @NO
    }];
    
    [generalInfoArr addObject:@{
        @"type" : kCellTypeZoom,
        @"title" : OALocalizedString(@"download_size"),
        @"value" : @"~ 1448 MB", // change
        @"clickable" : @NO
    }];
    [tableData addObject:mapTypeArr];
    [tableData addObject:zoomLevelArr];
    [tableData addObject:generalInfoArr];
    _data = @{
        @"tableData" : tableData,
    };
}

- (void) cancelPressed
{
    if (self.delegate)
        [self.delegate btnCancelPressed];
}

- (IBAction) cancelButtonPressed:(id)sender {
    if (self.delegate)
        [self.delegate btnCancelPressed];
}

- (IBAction) downloadButtonPressed:(id)sender {
    NSLog(@"Download button pressed");
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, [self getToolBarHeight], 0.0);
        if (self.delegate)
           [self.delegate requestFullMode];
        if (self.delegate && self.isLandscape)
            [self.delegate contentChanged];
        
        [self updateToolBar];
    } completion:nil];
}

- (void) updateToolBar
{
    _horizontalLine.frame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, 0.5);
    CGRect frame = self.bottomToolBarView.frame;
    frame.size.height = twoButtonsBottmomSheetHeight + [OAUtilities getBottomMargin];
    frame.origin.y = [self contentHeight] - frame.size.height;
    self.bottomToolBarView.frame = frame;
}

- (void) setupToolBarButtonsWithWidth:(CGFloat)width
{
    CGFloat w = width - 32.0 - OAUtilities.getLeftMargin;
    CGRect leftBtnFrame = _cancelButton.frame;
    CGRect rightBtnFrame = _downloadButton.frame;

    if (_downloadButton.isDirectionRTL)
    {
        rightBtnFrame.origin.x = 16.0 + OAUtilities.getLeftMargin;
        rightBtnFrame.size.width = w / 2 - 8;
        
        leftBtnFrame.origin.x = CGRectGetMaxX(rightBtnFrame) + 16.;
        leftBtnFrame.size.width = rightBtnFrame.size.width;

        _cancelButton.frame = leftBtnFrame;
        _downloadButton.frame = rightBtnFrame;
    }
    else
    {
        leftBtnFrame.origin.x = 16.0 + OAUtilities.getLeftMargin;
        leftBtnFrame.size.width = w / 2 - 8;
        _cancelButton.frame = leftBtnFrame;

        rightBtnFrame.origin.x = CGRectGetMaxX(leftBtnFrame) + 16.;
        rightBtnFrame.size.width = leftBtnFrame.size.width;
        _downloadButton.frame = rightBtnFrame;
    }
}

#pragma mark - TableView

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data[@"tableData"] count];
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kZoomSection)
    {
        if ([self pickerIsShown])
            return 4;
        return 3;
    }
    return [_data[@"tableData"][section] count];
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item =  [self getItem:indexPath];
 
    if ([item[@"type"] isEqualToString:@"OASettingsTableViewCell"])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.descriptionView setText: item[@"value"]];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OAPreviewZoomLevelsCell"])
    {
        static NSString* const identifierCell = @"OAPreviewZoomLevelsCell";
        OAPreviewZoomLevelsCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPreviewZoomLevelsCell" owner:self options:nil];
            cell = (OAPreviewZoomLevelsCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.descriptionLabel.text = item[@"value"];
            cell.minLevelZoomView.backgroundColor = UIColor.grayColor; // to delete
            cell.minZoomPropertyLabel.text = [NSString stringWithFormat:@"%ld",_minZoom];
            
            cell.maxLevelZoomView.backgroundColor = UIColor.grayColor;
            cell.maxZoomPropertyLabel.text = [NSString stringWithFormat:@"%ld",_maxZoom];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeZoom])
    {
        static NSString* const identifierCell = @"OATimeTableViewCell";
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATimeCell" owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.lbTitle.text = item[@"title"];
        cell.lbTime.text = item[@"value"];
        cell.lbTime.textColor = [item[@"clickable"] boolValue] ? [UIColor blackColor] : [UIColor grayColor];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypePicker])
    {
        static NSString* const identifierCell = @"OACustomPickerTableViewCell";
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OACustomPickerCell" owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
        }
        cell.dataArray = _possibleZoomValues;
        NSInteger minZoom = _minZoom >= kMinAllowedZoom && _minZoom <= kMaxAllowedZoom ? _minZoom : 1;
        NSInteger maxZoom = _maxZoom >= kMinAllowedZoom && _maxZoom <= kMaxAllowedZoom ? _maxZoom : 1;
        [cell.picker selectRow:indexPath.row == 2 ? minZoom - 1 : maxZoom - 1 inComponent:0 animated:NO];
        cell.picker.tag = indexPath.row;
        cell.delegate = self;
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 0.01;
    else if (section == 1)
        return 38;
    else
        return 8.0;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 1 ? OALocalizedString(@"res_zoom_levels") : @"";
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section == 1 ? UITableViewAutomaticDimension : 1.0;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 1 ? @"The detalization level increases the downloading size of map." : @""; // change
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath isEqual:_pickerIndexPath])
        return 162.0;
    return UITableViewAutomaticDimension;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item =  [self getItem:indexPath];
    if (indexPath.section == kZoomSection && ([item[@"type"] isEqualToString:kCellTypeZoom] || [item[@"type"] isEqualToString:kCellTypePicker]))
    {
        [self.tableView beginUpdates];

        if ([self pickerIsShown] && (_pickerIndexPath.row - 1 == indexPath.row))
            [self hideExistingPicker];
        else
        {
            NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker:indexPath];
            if ([self pickerIsShown])
                [self hideExistingPicker];

            [self showNewPickerAtIndex:newPickerIndexPath];
            _pickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row + 1 inSection:indexPath.section];
        }
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    if (indexPath.section == 0)
    {
        OASelectMapSourceViewController *mapSource = [[OASelectMapSourceViewController alloc] init];
        mapSource.delegate = self;
        [OARootViewController.instance.mapPanel presentViewController:mapSource animated:YES completion:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Picker

- (BOOL) pickerIsShown
{
    return _pickerIndexPath != nil;
}

- (void) hideExistingPicker
{
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row inSection:_pickerIndexPath.section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    _pickerIndexPath = nil;
}

- (void) hidePicker
{
    [self.tableView beginUpdates];
    if ([self pickerIsShown])
        [self hideExistingPicker];
    [self.tableView endUpdates];
}

- (NSIndexPath *) calculateIndexPathForNewPicker:(NSIndexPath *)selectedIndexPath
{
    NSIndexPath *newIndexPath;
    if (([self pickerIsShown]) && (_pickerIndexPath.row < selectedIndexPath.row))
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row - 1 inSection:kZoomSection];
    else
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row  inSection:kZoomSection];
    return newIndexPath;
}

- (void) showNewPickerAtIndex:(NSIndexPath *)indexPath
{
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:kZoomSection]];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[@"tableData"][indexPath.section][indexPath.row];
    if (indexPath.section == kZoomSection && [item[@"type"] isEqualToString:kCellTypeZoom])
    {
        NSArray *ar = _data[@"tableData"][indexPath.section];
        if ([self pickerIsShown])
        {
            if ([indexPath isEqual:_pickerIndexPath])
                return ar[3];
            else if (indexPath.row == 1)
                return ar[1];
            else
                return ar[2];
        }
        else
        {
            if (indexPath.row == 1)
                return ar[1];
            else if (indexPath.row == 2)
                return ar[2];
        }
    }
    return _data[@"tableData"][indexPath.section][indexPath.row];
}

- (void) zoomChanged:(NSString *)zoom tag: (NSInteger)pickerTag
{
    if (pickerTag == 2)
        _minZoom = [zoom intValue];
    else if (pickerTag == 3)
        _maxZoom = [zoom intValue];
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row - 1 inSection:_pickerIndexPath.section], [NSIndexPath indexPathForRow:0 inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - OAMapSourceSelectionDelegate

- (void) onNewSourceSelected
{
    [self setupView];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
