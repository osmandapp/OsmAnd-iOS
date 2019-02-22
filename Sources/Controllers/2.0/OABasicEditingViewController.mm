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
#import "OAEntity.h"
#import "MaterialTextFields.h"

#define kCellTypeTextInput @"text_input_cell"

@interface OABasicEditingViewController () <UITextViewDelegate, MDCMultilineTextInputLayoutDelegate>

@end

static const NSInteger _nameSectionIndex = 0;
static const NSInteger _nameSectionItemCount = 1;

@implementation OABasicEditingViewController
{
    OAEditPOIData *_poiData;
    id<OAOsmEditingDataProtocol> _dataProvider;
    
    NSArray *_data;
    
    OATextInputFloatingCell *_poiNameCell;
    
    MDCTextInputControllerUnderline *_textFieldControllerFloating;
    
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputFloatingCell" owner:self options:nil];
    _poiNameCell = (OATextInputFloatingCell *)[nib objectAtIndex:0];
//    _textFieldControllerFloating = [[MDCTextInputControllerUnderline alloc] initWithTextInput:_poiNameCell.inputField];
    _poiNameCell.inputField.underline.hidden = YES;
//    _poiNameCell.inputField.text = _poiData.getEntity.getNameTags.allValues.firstObject;
    _poiNameCell.inputField.placeholder = OALocalizedString(@"fav_name");
    _poiNameCell.inputField.textView.delegate = self;
    _poiNameCell.inputField.layoutDelegate = self;
    [_poiNameCell sizeToFit];
//    _poiNameCell.inputField.clearButton.imageView.image = [UIImage imageNamed:@""];

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
}

- (void) setupView
{
    _poiData = _dataProvider.getData;
    NSMutableArray *dataArr = [NSMutableArray new];
    [dataArr addObject:@{
                         @"name" : @"poi_name_input",
                         @"type" : kCellTypeTextInput,
                         }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == _nameSectionIndex && indexPath.row == 0)
        return _poiNameCell;

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return MAX(_poiNameCell.inputField.intrinsicContentSize.height - 20.0, 60.0);
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == _nameSectionIndex)
        return OALocalizedString(@"fav_name");
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

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

@end
