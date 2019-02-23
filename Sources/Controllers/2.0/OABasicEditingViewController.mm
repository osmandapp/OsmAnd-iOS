//
//  OABasicEditingViewController.m
//  OsmAnd
//
//  Created by Paul on 2/20/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABasicEditingViewController.h"
#import "OAOsmEditingViewController.h"
#import "OAEditPOIData.h"
#import "Localization.h"
#import "OATextInputFloatingCell.h"
#import "OASettingsTableViewCell.h"
#import "OAEntity.h"
#import "MaterialTextFields.h"
#import "OAColors.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OAPoiTypeSelectionViewController.h"
#import "OAPOIHelper.h"

#define kCellTypeTextInput @"text_input_cell"
#define kCellTypeSetting @"settings_cell"

@interface OABasicEditingViewController () <UITextViewDelegate, MDCMultilineTextInputLayoutDelegate>

@end

static const NSInteger _nameSectionIndex = 0;
static const NSInteger _nameSectionItemCount = 1;
static const NSInteger _poiSectionIndex = 1;

@implementation OABasicEditingViewController
{
    OAEditPOIData *_poiData;
    id<OAOsmEditingDataProtocol> _dataProvider;
    
    NSArray *_poiSectionItems;
    
    OATextInputFloatingCell *_poiNameCell;
    
    NSMutableArray *_floatingTextFieldControllers;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [[OABasicEditingViewController alloc] initWithNibName:@"OABasicEditingViewController" bundle:nil];
    if (self)
    {
        self.view.frame = frame;
    }
    return self;
}

-(void) setDataProvider:(id<OAOsmEditingDataProtocol>)provider
{
    _dataProvider = provider;
}

- (OATextInputFloatingCell *)getInputCellWithHint:(NSString *)hint text:(NSString *)text isFloating:(BOOL)isFloating
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputFloatingCell" owner:self options:nil];
    OATextInputFloatingCell *resultCell = (OATextInputFloatingCell *)[nib objectAtIndex:0];
    if (isFloating)
        [_floatingTextFieldControllers addObject:[[MDCTextInputControllerUnderline alloc] initWithTextInput:resultCell.inputField]];
    
    [resultCell.inputField.underline removeFromSuperview];
    //    _poiNameCell.inputField.text = _poiData.getEntity.getNameTags.allValues.firstObject;
    resultCell.inputField.placeholder = hint;
    resultCell.inputField.textView.delegate = self;
    resultCell.inputField.layoutDelegate = self;
    [resultCell sizeToFit];
    resultCell.inputField.clearButton.imageView.tintColor = UIColorFromRGB(color_icon_color);
    [resultCell.inputField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [resultCell.inputField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    return resultCell;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
}

-(void) populatePoiSection
{
    NSMutableArray *dataArr = [NSMutableArray new];
    [dataArr addObject:@{
                         @"name" : @"poi_category",
                         @"title" : OALocalizedString(@"shared_string_category"),
                         @"value" : _poiData.getPoiCategory != [OAPOIHelper sharedInstance].otherPoiCategory ? _poiData.getPoiCategory.nameLocalized :
                             OALocalizedString(@"shared_string_select"),
                         @"type" : kCellTypeSetting,
                         }];
    [dataArr addObject:@{
                         @"name" : @"poi_type",
                         @"title" : OALocalizedString(@"poi_type"),
                         @"value" : _poiData.getCurrentPoiType ? _poiData.getCurrentPoiType.nameLocalized :
                             OALocalizedString(@"shared_string_select"),
                         @"type" : kCellTypeSetting,
                         }];
    _poiSectionItems = [NSArray arrayWithArray:dataArr];
}

- (void) setupView
{
    _poiData = _dataProvider.getData;
    _floatingTextFieldControllers = [NSMutableArray new];
    _poiNameCell = [self getInputCellWithHint:OALocalizedString(@"fav_name") text:@"" isFloating:NO];
    [self populatePoiSection];
}

-(NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    if (indexPath.section == _poiSectionIndex)
        return _poiSectionItems[indexPath.row];
    else
        return [NSDictionary new];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case _nameSectionIndex:
            return _nameSectionItemCount;
        case _poiSectionIndex:
            return _poiSectionItems.count;
        default:
            return 1;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    if (indexPath.section == _nameSectionIndex && indexPath.row == 0)
        return _poiNameCell;
    else if ([item[@"type"] isEqualToString:kCellTypeSetting])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText:item[@"title"]];
            [cell.descriptionView setText:item[@"value"]];
        }
        return cell;
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    if (indexPath.section == _nameSectionIndex)
        return MAX(_poiNameCell.inputField.intrinsicContentSize.height, 44.0);
    else if ([item[@"type"] isEqualToString:kCellTypeSetting])
        return [OASettingsTableViewCell getHeight:item[@"title"] value:item[@"value"] cellWidth:self.tableView.bounds.size.width];
    else
        return 44.0;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == _nameSectionIndex)
        return OALocalizedString(@"fav_name");
    else if (section == _poiSectionIndex)
        return OALocalizedString(@"poi_category_and_type");
    else
        return @"";
}

#pragma mark - UITextViewDelegate
-(void)textViewDidChange:(UITextView *)textView
{
//    [UIView setAnimationsEnabled:NO];
//    [textView sizeToFit];
//    [self.tableView beginUpdates];
//    [self.tableView endUpdates];
//    [UIView setAnimationsEnabled:YES];
}

- (void)multilineTextField:(id<MDCMultilineTextInput> _Nonnull)multilineTextField
      didChangeContentSize:(CGSize)size
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:kCellTypeSetting])
    {
        OAPoiTypeSelectionViewController *detailViewController = [[OAPoiTypeSelectionViewController alloc]
                                                                  initWithType:(indexPath.row == 0 ? CATEGORY_SCREEN : POI_TYPE_SCREEN)];
        detailViewController.dataProvider = _dataProvider;
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
}


@end
