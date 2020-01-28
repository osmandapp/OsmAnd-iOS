//
//  OAOnlineTilesEditingViewController.m
//  OsmAnd Maps
//
//  Created by igor on 23.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAOnlineTilesEditingViewController.h"
#import "Localization.h"
#import "OASQLiteTileSource.h"
#import "OATextInputFloatingCell.h"
#import "OAColors.h"
#import "OATimeTableViewCell.h"
#import "OASettingsTableViewCell.h"
#import "OACustomPickerTableViewCell.h"

#define kNameSection 0
#define kURLSection 1
#define kZoomSection 2
#define kExpireSection 3
#define kMercatorSection 4

#define kCellTypeTextInput @"text_input_cell"
#define kCellTypeSetting @"settings_cell"
#define kCellTypeZoom @"time_cell"
#define kCellTypePicker @"picker"

@interface OAOnlineTilesEditingViewController () <UITextViewDelegate, MDCMultilineTextInputLayoutDelegate>

@end

@implementation OAOnlineTilesEditingViewController
{
    OnlineTilesResourceItem *localItem;
    
    NSString *itemName;
    NSString *itemURL;
    int minZoom;
    int maxZoom;
    long expireTimeMinutes;
    long expireTimeMillis;
    BOOL isEllipticYTile;

    NSMutableArray *_floatingTextFieldControllers;
    NSDictionary *data;
    NSArray *zoomArray;
    NSArray *sectionHeaderFooterTitles;
    
    NSMutableArray *possibleZoomValues;
    
    NSIndexPath *pickerIndexPath;
    BOOL pickerIsShown;
}
-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"res_edit_online_map");
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

-(id) initWithLocalOnlineSourceItem:(OnlineTilesResourceItem *)item
{
    self = [super init];
    if (self) {
        localItem = item;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    OASQLiteTileSource *ts = [[OASQLiteTileSource alloc] initWithFilePath:localItem.path];
    itemName = ts.name;
    itemURL = ts.urlTemplate;
    minZoom = ts.minimumZoomSupported;
    maxZoom = ts.maximumZoomSupported;
    expireTimeMinutes = ts.getExpirationTimeMinutes;
    expireTimeMillis = ts.getExpirationTimeMillis;
    isEllipticYTile = ts.isEllipticYTile;
    
    possibleZoomValues = [NSMutableArray new];
    for (int i = 1; i <= 22; i++)
        [possibleZoomValues addObject: @(i)];
    NSLog (@"The 4th integer is: %ld", [possibleZoomValues[3] integerValue]);
    
    NSMutableArray *zoomArr = [NSMutableArray new];
    [zoomArr addObject:@{
                        @"title": OALocalizedString(@"rec_interval_minimum"),
                        @"value" : [NSString stringWithFormat:@"%d", minZoom],
                        @"type" : kCellTypeZoom,
                         }];
    [zoomArr addObject:@{
                        @"title": OALocalizedString(@"shared_string_maximum"),
                        @"value" : [NSString stringWithFormat:@"%d", maxZoom],
                        @"type" : kCellTypeZoom,
                         }];
    [zoomArr addObject:@{
                        @"type" : kCellTypePicker,
                         }];
    zoomArray = [NSArray arrayWithArray: zoomArr];
    NSMutableDictionary *tableData = [NSMutableDictionary new];
    [tableData setObject:@{
                        @"title" : itemName,
                        @"type" : kCellTypeTextInput,
                    }
             forKey:@"0"];
    [tableData setObject:@{
                        @"title" : @"",//itemURL,
                        @"type" : kCellTypeTextInput,
                    }
             forKey:@"1"];
    [tableData setObject: zoomArr
             forKey:@"2"];
    [tableData setObject:@{
                          @"title" : [NSString stringWithFormat:@"%ld", expireTimeMillis],
                          @"type" : kCellTypeTextInput,
                    }
             forKey:@"3"];
    [tableData setObject:@{
                        @"title": OALocalizedString(@"res_mercator"),
                        @"value" : isEllipticYTile ? OALocalizedString(@"res_elliptic_mercator") : OALocalizedString(@"res_pseudo_mercator"),
                        @"type" : kCellTypeSetting,
                    }
             forKey:@"4"];
    data = [NSDictionary dictionaryWithDictionary:tableData];
    
    NSMutableArray *sectionArr = [NSMutableArray new];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"fav_name"),
                        @"footer" : OALocalizedString(@"res_online_name_descr")
                        }];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"res_url"),
                        @"footer" : OALocalizedString(@"res_online_url_descr")
                        }];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"res_zoom_levels"),
                        @"footer" : @"aaaaaaaaaaaaaaa"//OALocalizedString(@"")
                        }];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"res_expire_time"),
                        @"footer" : @"aaaaaaaaaaaaaaa"//OALocalizedString(@"")
                        }];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@""),
                        @"footer" : @"aaaaaaaaaaaaaaa"//OALocalizedString(@"")
                        }];
    sectionHeaderFooterTitles = [NSArray arrayWithArray:sectionArr];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (OATextInputFloatingCell *)getInputCellWithHint:(NSString *)hint text:(NSString *)text isFloating:(BOOL)isFloating tag:(NSInteger)tag
{
    static NSString* const identifierCell = @"OATextInputFloatingCell";
    OATextInputFloatingCell* resultCell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (resultCell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputFloatingCell" owner:self options:nil];
        resultCell = (OATextInputFloatingCell *)[nib objectAtIndex:0];
    }
    if (resultCell)
    {
        MDCMultilineTextField *textField = resultCell.inputField;
        [textField.underline removeFromSuperview];
        textField.placeholder = hint;
        [textField.textView setText:text];
        textField.textView.delegate = self;
        textField.layoutDelegate = self;
        textField.textView.tag = tag;
        textField.clearButton.tag = tag;
        [textField.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        textField.font = [UIFont systemFontOfSize:17.0];
        textField.clearButton.imageView.tintColor = UIColorFromRGB(color_icon_color);
        [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
        if (!_floatingTextFieldControllers)
            _floatingTextFieldControllers = [NSMutableArray new];
        if (isFloating)
        {
            MDCTextInputControllerUnderline *fieldController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:textField];
            fieldController.inlinePlaceholderFont = [UIFont systemFontOfSize:16.0];
            fieldController.floatingPlaceholderActiveColor = fieldController.floatingPlaceholderNormalColor;
            fieldController.textInput.textInsetsMode = MDCTextInputTextInsetsModeIfContent;
            [_floatingTextFieldControllers addObject:fieldController];
            
        }
    }
    return resultCell;
}

- (IBAction)saveButtonPressed:(UIButton *)sender
{
}

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)pickerIsShown
{
    return pickerIndexPath != nil;
}

- (void)hideExistingPicker {
    
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:pickerIndexPath.row inSection:pickerIndexPath.section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    pickerIndexPath = nil;
}

-(NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    NSString* section = [NSString stringWithFormat:@"%ld", indexPath.section];
    if (indexPath.section != kZoomSection)
        return data[section];
    else
    {
        NSArray *ar = data[section];
        if ([self pickerIsShown])
        {
            if ([indexPath isEqual:pickerIndexPath])
                return ar[2];
            else if (indexPath.row == 0)
                return ar[0];
            else
                return ar[1];
        }
        else
        {
            if (indexPath.row == 0)
                return ar[0];
            else if (indexPath.row == 1)
                return ar[1];
        }
    }
    return [NSDictionary new];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *data =  [self getItem:indexPath];
    
    if ([data[@"type"] isEqualToString:kCellTypeTextInput])
        return [self getInputCellWithHint:@"" text:data[@"title"] isFloating:YES tag:0];
    else if ([data[@"type"] isEqualToString:kCellTypeSetting])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }

        if (cell) {
            [cell.textView setText:data[@"title"]];
            [cell.descriptionView setText:data[@"value"]];
        }
        return cell;
    }

    else if ([data[@"type"] isEqualToString:kCellTypeZoom])
    {
        static NSString* const identifierCell = @"OATimeTableViewCell";
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATimeCell" owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.lbTitle.text = data[@"title"];
        cell.lbTime.text = data[@"value"];
        cell.lbTime.textColor = [UIColor blackColor];

        return cell;
    }
//    else if ([data[@"type"] isEqualToString:kCellTypePicker])
//    {
//        static NSString* const identifierCell = @"OACustomPickerTableViewCell";
//        OACustomPickerTableViewCell* cell;
//        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
//        if (cell == nil)
//        {
//            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OACustomPickerCell" owner:self options:nil];
//            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
//        }
//        NSArray *arr;
//        arr = [NSArray arrayWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20", @"21", @"22", nil];
//        cell.dataArray = arr;
//
//        return cell;
//    }
    
//    else if ([self datePickerIsShown] && [_datePickerIndexPath isEqual:indexPath])
//    {
//        static NSString* const reusableIdentifierTimePicker = @"OADateTimePickerTableViewCell";
//        OADateTimePickerTableViewCell* cell;
//        cell = (OADateTimePickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierTimePicker];
//        if (cell == nil)
//        {
//            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADateTimePickerCell" owner:self options:nil];
//            cell = (OADateTimePickerTableViewCell *)[nib objectAtIndex:0];
//        }
//        cell.dateTimePicker.datePickerMode = UIDatePickerModeTime;
//        cell.dateTimePicker.date = indexPath.row - 1 == 1 ? _startDate : _endDate;
//        [cell.dateTimePicker removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
//        [cell.dateTimePicker addTarget:self action:@selector(timePickerChanged:) forControlEvents:UIControlEventValueChanged];
//
//        return cell;
//    }
    else
        return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if ([item[@"type"] isEqualToString:kCellTypeTimeRightDetail])
//    {
//        [self.tableView beginUpdates];
//
//        if ([self datePickerIsShown] && (_datePickerIndexPath.row - 1 == indexPath.row))
//            [self hideExistingPicker];
//        else
//        {
//            NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker:indexPath];
//            if ([self datePickerIsShown])
//                [self hideExistingPicker];
//
//            [self showNewPickerAtIndex:newPickerIndexPath];
//            _datePickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row + 1 inSection:indexPath.section];
//        }
//
//        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
//        [self.tableView endUpdates];
//        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
//    }
}
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kZoomSection)
        return 2;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return sectionHeaderFooterTitles[section][@"header"];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return sectionHeaderFooterTitles[section][@"footer"];
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if (indexPath.section != kZoomSection)
    {
        if ([item[@"type"] isEqualToString:kCellTypeSetting])
            return [OASettingsTableViewCell getHeight:item[@"title"] value:item[@"value"] cellWidth:self.tableView.bounds.size.width];
        if ([item[@"type"] isEqualToString:kCellTypeTextInput])
        {
            OATextInputFloatingCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            return MAX(cell.inputField.intrinsicContentSize.height, 44.0);
            //return 44;
        }
    }
    else
    {
        if ([indexPath isEqual:pickerIndexPath])
            return 162.0;
        else
            return 44.0;
    }
}



@end
