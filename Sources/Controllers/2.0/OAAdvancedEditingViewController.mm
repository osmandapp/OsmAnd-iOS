//
//  OAAdvancedEditingViewController.m
//  OsmAnd
//
//  Created by Paul on 3/27/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAAdvancedEditingViewController.h"
#import "OAOsmEditingViewController.h"
#import "OADescrTitleCell.h"
#import "OATextInputFloatingCellWithIcon.h"
#import "OAButtonCell.h"
#import "OAEditPOIData.h"
#import "Localization.h"
#import "OAColors.h"
#import "MaterialTextFields.h"
#import "OAOSMSettings.h"
#import "OAEditPOIData.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"

#define kDescrText @"OADescrTitleCell"
#define kInputImage @"OATextInputFloatingCellWithIcon"
#define kButtonCell @"OAButtonCell"

@interface OAAdvancedEditingViewController () <UITextViewDelegate, MDCMultilineTextInputLayoutDelegate>

@property (strong, nonatomic) IBOutlet UIView *toolbarView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak) UITextView *tagTextView;

@end

@implementation OAAdvancedEditingViewController
{
    OAEditPOIData *_poiData;
    id<OAOsmEditingDataProtocol> _dataProvider;
    
    NSMutableArray *_fieldPairs;
    
    BOOL _isKeyboardShown;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [[OAAdvancedEditingViewController alloc] initWithNibName:@"OAAdvancedEditingViewController" bundle:nil];
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

- (OADescrTitleCell *)getTextCellWithDescr:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    OADescrTitleCell *resultCell = nil;
    resultCell = [self.tableView dequeueReusableCellWithIdentifier:kDescrText];
    if (resultCell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kDescrText owner:self options:nil];
        resultCell = (OADescrTitleCell *)[nib objectAtIndex:0];
    }
    resultCell.descriptionView.text = item[@"hint"];
    resultCell.textView.text = item[@"value"];
    resultCell.textView.hidden = resultCell.textView.text.length == 0;
    
    resultCell.userInteractionEnabled = NO;
    return resultCell;
}

- (OATextInputFloatingCellWithIcon *)getInputCellWithHint:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    OATextInputFloatingCellWithIcon *resultCell = nil;
    resultCell = [self.tableView dequeueReusableCellWithIdentifier:kInputImage];
    if (resultCell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kInputImage owner:self options:nil];
        resultCell = (OATextInputFloatingCellWithIcon *)[nib objectAtIndex:0];
    }
    if (item[@"img"] && ![item[@"img"] isEqualToString:@""]) {
        resultCell.buttonView.hidden = NO;
        [resultCell.buttonView setImage:[UIImage imageNamed:item[@"img"]] forState:UIControlStateNormal];
        [resultCell.buttonView addTarget:self action:@selector(deleteSectionPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
        resultCell.buttonView.hidden = YES;
    
    resultCell.fieldLabel.text = item[@"hint"];
    MDCMultilineTextField *textField = resultCell.textField;
    textField.underline.hidden = YES;
    textField.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.placeholder = @"";
    [textField.textView setText:item[@"value"]];
    textField.textView.delegate = self;
    textField.layoutDelegate = self;
    [textField.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    textField.font = [UIFont systemFontOfSize:17.0];
    textField.clearButton.imageView.tintColor = UIColorFromRGB(color_icon_color);
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    
    return resultCell;
}

- (OAButtonCell *) getAddTagButtonCell
{
    static NSString* const identifierCell = @"OAButtonCell";
    OAButtonCell* cell = nil;
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAButtonCell" owner:self options:nil];
        cell = (OAButtonCell *)[nib objectAtIndex:0];
    }
    if (cell)
    {
        [cell.button setTitle:OALocalizedString(@"shared_string_add") forState:UIControlStateNormal];
        [cell.button addTarget:self action:@selector(addTag:) forControlEvents:UIControlEventTouchDown];
        [cell showImage:YES];
        cell.iconView.image = [UIImage imageNamed:@"ic_custom_add"];
    }
    return cell;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self setupView];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) setupView
{
    _poiData = _dataProvider.getData;
    _fieldPairs = [NSMutableArray new];
    OAPOIType *pt = _poiData.getCurrentPoiType;
    NSString *hint = OALocalizedString(@"amenity");
    NSString *value = @"";
    if (pt && !pt.nonEditableOsm)
    {
        hint = pt.getEditOsmTag;
        value = pt.getEditOsmValue;
    }
    else
    {
        OAPOICategory *category = _poiData.getPoiCategory;
        if (category && !category.nonEditableOsm)
            hint = category.name;
       
        value = _poiData.getPoiTypeString;
    }
    NSString *poiName = [_poiData getTag:[OAOSMSettings getOSMKey:NAME]];
    
    NSArray *nameTypePair = @[
                              [self getDictionary:kDescrText hint:OALocalizedString(@"fav_name") value:poiName image:nil],
                              [self getDictionary:kDescrText hint:hint value:value image:nil]
                              ];
    [_fieldPairs addObject:nameTypePair];
    
    NSString *currentPoiTypeKey = @"";
    if (pt)
        currentPoiTypeKey = pt.getEditOsmTag;
    
    [_poiData.getTagValues enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        if (![key isEqualToString:POI_TYPE_TAG]
            && ![key isEqualToString:[OAOSMSettings getOSMKey:NAME]]
            && ![key hasPrefix:REMOVE_TAG_PREFIX]
            && ![key isEqualToString:currentPoiTypeKey]) {
            [_fieldPairs addObject:@[
                                     @{
                                         @"type" : kInputImage,
                                         @"hint" : OALocalizedString(@"osm_tag"),
                                         @"value" : key,
                                         @"img" : @"ic_custom_delete"
                                         },
                                     @{
                                         @"type" : kInputImage,
                                         @"hint" : OALocalizedString(@"osm_value"),
                                         @"value" : value,
                                         @"img" : @""
                                         }
                                     ]];
        }
    }];
    [_fieldPairs addObject:@[
                            @{
                                @"type" : kButtonCell
                                }
                            ]];
    [self.tableView reloadData];
}

-(NSDictionary *) getDictionary:(nonnull NSString *)type hint:(nonnull NSString *)hint value:(nullable NSString *)value image:(nullable NSString *)image
{
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary setObject:type forKey:@"type"];
    [dictionary setObject:hint forKey:@"hint"];
    if (value && value.length > 0)
        [dictionary setObject:value forKey:@"value"];
    if (image && image.length > 0)
        [dictionary setObject:image forKey:@"img"];
    return [NSDictionary dictionaryWithDictionary:dictionary];
    
}

- (void) addTagPair:(NSInteger)index
{
    [_fieldPairs insertObject:@[
                                [self getDictionary:kInputImage hint:OALocalizedString(@"osm_tag") value:nil image:@"ic_custom_delete"],
                                [self getDictionary:kInputImage hint:OALocalizedString(@"osm_value") value:nil image:nil]
                                ] atIndex:index];
}

-(NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    NSArray *pair = _fieldPairs[indexPath.section];
    return pair[indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    if ([item[@"type"] isEqualToString:kButtonCell])
        [self addTag:nil];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell canBecomeFirstResponder])
        [cell becomeFirstResponder];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:kDescrText])
        return [self getTextCellWithDescr:indexPath];
    else if ([item[@"type"] isEqualToString:kInputImage])
        return [self getInputCellWithHint:indexPath];
    else if ([item[@"type"] isEqualToString:kButtonCell])
        return [self getAddTagButtonCell];
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:kInputImage])
        return [OATextInputFloatingCellWithIcon getHeight:item[@"value"] desc:item[@"hint"] cellWidth:DeviceScreenWidth];
    else if ([item[@"type"] isEqualToString:kDescrText])
        return [OADescrTitleCell getHeight:item[@"value"] desc:item[@"hint"] cellWidth:DeviceScreenWidth];
    return 44.0;
}

#pragma mark - UITextViewDelegate

-(void)textViewDidChange:(UITextView *)textView
{

    NSIndexPath *indexPath = [self indexPathForCellContainingView:textView inTableView:self.tableView];
    if (indexPath.section < _fieldPairs.count)
    {
        NSArray *cellPair = _fieldPairs[indexPath.section];
        BOOL tagChanged = indexPath.row == 0;
        NSDictionary *tagCellInfo = cellPair[0];
        NSDictionary *valueCellInfo = cellPair[1];
        NSString *tag = tagCellInfo[@"value"];
        NSString *value = valueCellInfo[@"value"];
        if (tagChanged)
        {
            if (tag)
                [_poiData removeTag:tag];
            if (textView.text.length > 0 && value && value.length > 0)
                [_poiData putTag:textView.text value:value];

            [_fieldPairs setObject:@[
                                     [self getDictionary:tagCellInfo[@"type"]
                                                    hint:tagCellInfo[@"hint"] value:textView.text image:@"ic_custom_delete"],
                                     valueCellInfo
                                     ] atIndexedSubscript:indexPath.section];

            if (self.tagTextView == nil)
                self.tagTextView = textView;

            [self toggleTagToolbar];

            [self createTagHintsSetIfNeededWith: textView.text];
        }
        else
        {
            if (tag && tag.length > 0)
                [_poiData putTag:tag value:textView.text];
            
            [_fieldPairs setObject:@[
                                     tagCellInfo,
                                     [self getDictionary:valueCellInfo[@"type"] hint:valueCellInfo[@"hint"] value:textView.text image:nil]
                                     ] atIndexedSubscript:indexPath.section];
        }
    }
}

#pragma mark - MDCMultilineTextInputLayoutDelegate
- (void)multilineTextField:(id<MDCMultilineTextInput> _Nonnull)multilineTextField
      didChangeContentSize:(CGSize)size
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _fieldPairs.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *pair = _fieldPairs[section];
    return pair.count;
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    if (!_isKeyboardShown) {
        [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
            [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 44.0, insets.right)];
            [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(insets.top, insets.left, 44.0, insets.right)];
        } completion:nil];
    }
    _isKeyboardShown = YES;
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    if (_isKeyboardShown)
    {
        [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
            // Temporary fix for iOS 9/10 due to strange scroll behavior
//            [self.tableView setContentInset:UIEdgeInsetsZero];
//            [self.tableView setScrollIndicatorInsets:UIEdgeInsetsZero];
            [self.view layoutIfNeeded];
        } completion:nil];
    }
    _isKeyboardShown = NO;
}

- (NSIndexPath *)indexPathForCellContainingView:(UIView *)view inTableView:(UITableView *)tableView {
    CGPoint viewCenterRelativeToTableview = [tableView convertPoint:CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds)) fromView:view];
    NSIndexPath *cellIndexPath = [tableView indexPathForRowAtPoint:viewCenterRelativeToTableview];
    return cellIndexPath;
}

-(void) clearButtonPressed:(UIButton *)sender
{
    NSIndexPath *indexPath = [self indexPathForCellContainingView:sender inTableView:self.tableView];
    [self.tableView beginUpdates];
    NSArray *pair = _fieldPairs[indexPath.section];
    NSDictionary *tagCellInfo = pair[0];
    NSDictionary *valueInfo = pair[1];
    NSString *oldKey = tagCellInfo[@"value"];
    if (oldKey && oldKey.length > 0)
        [_poiData removeTag:oldKey];
    
    BOOL clearedTag = indexPath.row == 0;
    if (clearedTag)
    {
        _fieldPairs[indexPath.section] = @[
                                           [self getDictionary:tagCellInfo[@"type"] hint:tagCellInfo[@"hint"] value:nil image:@"ic_custom_delete"],
                                           valueInfo
                                           ];

        [self hideTagToolbar];
    }
    else
    {
        _fieldPairs[indexPath.section] = @[
                                           tagCellInfo,
                                           [self getDictionary:valueInfo[@"type"] hint:valueInfo[@"hint"] value:nil image:nil]
                                           ];
    }
    [self.tableView endUpdates];
}

-(void) deleteSectionPressed:(UIButton *)sender
{
    NSIndexPath *indexPath = [self indexPathForCellContainingView:sender inTableView:self.tableView];
    [self.tableView beginUpdates];
    NSArray *pair = _fieldPairs[indexPath.section];
    NSDictionary *tagCellInfo = pair[0];
    NSString *tagName = tagCellInfo[@"value"];
    
    [_poiData removeTag:tagName ? tagName : @""];
    [_fieldPairs removeObjectAtIndex:indexPath.section];
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

-(void) addTag:(UIButton *)sender
{
    NSInteger sectionNumber = _fieldPairs.count - 1;
    [self.tableView beginUpdates];
    [self addTagPair:sectionNumber];
    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionNumber] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:sectionNumber + 1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

-(void)createTagToolbarFor
{
    //need to check for version cause inputAssistantItem only available in iOS9+
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSOperatingSystemVersion iOS9Version = {9, 0, 0};

    if ([processInfo isOperatingSystemAtLeastVersion:iOS9Version])
    {
        UITextInputAssistantItem* item = self.tagTextView.inputAssistantItem;
        item.leadingBarButtonGroups = @[];
        item.trailingBarButtonGroups = @[];
        self.tagTextView.inputAccessoryView = self.toolbarView;
        [self.tagTextView reloadInputViews];
    }
}

-(void)toggleTagToolbar
{
    if (self.tagTextView.inputAccessoryView == nil)
        [self createTagToolbarFor];
    else if ([self.tagTextView.text isEqualToString:@""])
        [self hideTagToolbar];
}

-(void)hideTagToolbar
{
    self.tagTextView.inputAccessoryView = nil;
    [self.tagTextView reloadInputViews];
}

-(void)createTagHintsSetIfNeededWith:(NSString*) tag
{
    OAAdvancedEditingViewController* __weak weakSelf = self;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSArray* hints = [_poiData getTranslatedSubTypesMatchingWith:tag];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            OAAdvancedEditingViewController* __weak strongSelf = weakSelf;
            [strongSelf updateTagHints:hints];
        });
    });
}

-(void)updateTagHints:(NSArray *)hints {
    NSInteger xPosition = 0;
    NSInteger margin = 8;

    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.contentSize = CGSizeMake(margin, self.toolbarView.frame.size.height);

    if ([hints count] == 0)
        [self hideTagToolbar];
    else
        for ( NSString* hint in hints )
        {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(xPosition + margin, 6, 0, 0)];
            label.backgroundColor = UIColorFromRGB(tag_hint_background_color);
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = UIColorFromRGB(tag_hint_text_color);
            label.layer.masksToBounds = YES;
            label.layer.cornerRadius = 4.0;
            label.numberOfLines = 1;
            label.text = hint;
            [label sizeToFit];

            UITapGestureRecognizer* gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tagHintTapped:)];
            [label setUserInteractionEnabled: YES];
            [label addGestureRecognizer: gesture];

            CGRect labelFrame = [label frame];
            labelFrame.size.width = label.frame.size.width + 15;
            labelFrame.size.height = 32;
            [label setFrame:labelFrame];

            xPosition += label.frame.size.width + margin;

            [self.scrollView addSubview:label];
        }
    self.scrollView.contentSize = CGSizeMake(xPosition, self.toolbarView.frame.size.height);

    [self.tagTextView reloadInputViews];
}

-(void)removeFromSuperview:(UITapGestureRecognizer*)sender
{
    if ([sender isKindOfClass:[UILabel class]])
    {
        UILabel *label = (UILabel *) sender;
        [label removeFromSuperview];
    }
}

-(void)tagHintTapped:(UIGestureRecognizer*)gestureRecognizer
{
    self.tagTextView.text = [(UILabel*)gestureRecognizer.view text];
    [self hideTagToolbar];
}


@end
