//
//  OACustomSourceDetailsViewController.m
//  OsmAnd Maps
//
//  Created by Paul on 30.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACustomSourceDetailsViewController.h"
#import "OADownloadDescriptionInfo.h"
#import "OACustomRegion.h"
#import "OAResourcesUIHelper.h"
#import "OAOnlyImageViewCell.h"
#import "OATextViewSimpleCell.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "OAFilledButtonCell.h"
#import "OAResourcesUIHelper.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAImagesTableViewCell.h"

#define imageViewHeight 200.0

@interface OACustomSourceDetailsViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

@end

@implementation OACustomSourceDetailsViewController
{
    OACustomResourceItem *_item;
    OACustomRegion *_region;
    
    NSArray<NSDictionary *> *_data;
    __block NSMutableArray<UIImage *> *_downloadedImages;
    BOOL _queriedImages;
    
    OADownloadActionButton *_downloadButton;
}

- (instancetype) initWithCustomItem:(OACustomResourceItem *)item region:(OACustomRegion *)region
{
    self = [super init];
    if (self) {
        _item = item;
        _region = region;
        [self generateData];
    }
    return self;
}

- (void)applyLocalization
{
    self.titleView.text = _item.getVisibleName;
}

- (void)queryImage
{
    _downloadedImages = [NSMutableArray new];
    if (_item.descriptionInfo.imageUrls.count > 0 && !_queriedImages)
    {
        NSURLSession *imageDownloadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        __block int processedUrlsCount = 0;
        for (NSString *imageUrl in _item.descriptionInfo.imageUrls)
        {
            [[imageDownloadSession dataTaskWithURL:[NSURL URLWithString:imageUrl] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                
                processedUrlsCount++;
                if (((NSHTTPURLResponse *)response).statusCode == 200)
                {
                    if (data)
                    {
                        UIImage *img = [UIImage imageWithData:data];
                        if (img)
                        {
                            [_downloadedImages addObject:img];
                            if (processedUrlsCount == _item.descriptionInfo.imageUrls.count)
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self generateData];
                                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                                    _queriedImages = YES;
                                });
                            }
                        }
                    }
                }
            }] resume];
        }
    }
}

- (void) generateData
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];
    
    if (_downloadedImages.count == 1)
    {
        [data addObject:@{
            @"type" : [OAOnlyImageViewCell getCellIdentifier]
        }];
    }
    else if (_downloadedImages.count > 1)
    {
        [data addObject:@{
            @"type" : [OAImagesTableViewCell getCellIdentifier]
        }];
    }
    
    [data addObject:@{
        @"type" : [OAMenuSimpleCellNoIcon getCellIdentifier],
        @"title" : _item.getVisibleName ? : @"",
        @"descr" : [NSByteCountFormatter stringFromByteCount:_item.sizePkg countStyle:NSByteCountFormatterCountStyleFile]
    }];
    
    if (_item.descriptionInfo.getLocalizedDescription.length > 0)
    {
        NSAttributedString *attrString = [OAUtilities attributedStringFromHtmlString:_item.descriptionInfo.getLocalizedDescription fontSize:17];
        [data addObject:@{
                @"type" : [OATextViewSimpleCell getCellIdentifier],
                @"attrText" : attrString
        }];
    }
    _data = data;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.actionButton.layer.cornerRadius = 9.;
    self.navBarView.backgroundColor = _region.headerColor;
    
    [self queryImage];
    [self setupActionButtons];
}

- (void)viewWillLayoutSubviews
{
    [_tableView reloadData];
}

- (void) setupActionButtons
{
    OADownloadActionButton *downloadButton = nil;
    NSMutableArray<OADownloadActionButton *> *actionButtons = [NSMutableArray arrayWithArray:_item.descriptionInfo.getActionButtons];
    BOOL isDownloading = [[OsmAndApp instance].downloadsManager.keysOfDownloadTasks containsObject:[NSString stringWithFormat:@"resource:%@", _item.resourceId.toNSString()]];
    if (actionButtons.count == 0 && _item && !_item.isInstalled && !isDownloading)
        downloadButton = [[OADownloadActionButton alloc] initWithActionType:DOWNLOAD_BUTTON_ACTION name:OALocalizedString(@"download") url:nil];
    
    NSMutableArray<NSDictionary *> *additionalButtons = [NSMutableArray array];
    for (OADownloadActionButton *actionButton in actionButtons)
    {
        if (actionButton.url)
        {
            [additionalButtons addObject:@{
                @"type" : [OAFilledButtonCell getCellIdentifier],
                @"button" : actionButton
            }];
        }
        else if (!downloadButton && [actionButton.actionType isEqualToString:DOWNLOAD_BUTTON_ACTION] && !_item.isInstalled && isDownloading)
        {
            downloadButton = actionButton;
        }
    }
    if (additionalButtons.count > 0)
    {
        _data = [_data arrayByAddingObjectsFromArray:additionalButtons];
        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self setupDownloadButton:downloadButton];
}

- (void) setupDownloadButton:(OADownloadActionButton *)downloadButton
{
    _downloadButton = downloadButton;
    BOOL active = downloadButton != nil;
    [self.actionButton setTitle:active ? downloadButton.name : OALocalizedString(@"show_region_on_map_title") forState:UIControlStateNormal];
    self.actionButton.backgroundColor = active ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_route_button_inactive);
    [self.actionButton setTitleColor:active ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
    [self.actionButton setUserInteractionEnabled:active];
}

- (IBAction)actionButtonPressed:(id)sender
{
    if (_downloadButton)
    {
        [OAResourcesUIHelper startDownloadOfCustomItem:_item onTaskCreated:^(id<OADownloadTask> task) {
            [self.navigationController popViewControllerAnimated:YES];
        } onTaskResumed:^(id<OADownloadTask> task) {
        }];
    }
}

- (void) onActionPressed:(UIButton *)sender
{
    if (sender.tag < _data.count)
    {
        OADownloadActionButton *button = _data[sender.tag][@"button"];
        if (button.url)
            [self openUrl:button.url];
    }
}

- (void) openUrl:(NSString *)urlStr
{
    NSURL *url = [NSURL URLWithString:urlStr];
    if ([[UIApplication sharedApplication] canOpenURL:url])
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

// MARK: UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OAMenuSimpleCellNoIcon getCellIdentifier]])
    {
        OAMenuSimpleCellNoIcon *cell = (OAMenuSimpleCellNoIcon *)[tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCellNoIcon getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:type owner:self options:nil];
            cell = (OAMenuSimpleCellNoIcon *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        if (cell)
        {
            cell.descriptionView.hidden = item[@"descr"] == nil || [item[@"descr"] length] == 0 ? YES : NO;
            [cell.textView setText:item[@"title"]];
            [cell.descriptionView setText:item[@"descr"]];
            if ([cell needsUpdateConstraints])
                [cell updateConstraints];
        }
        return cell;
    }
    else if ([type isEqualToString:[OATextViewSimpleCell getCellIdentifier]])
    {
        OATextViewSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextViewSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextViewSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OATextViewSimpleCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsZero;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.attributedText = item[@"attrText"];
            cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple)};
            [cell.textView sizeToFit];
        }
        return cell;
    }
    else if ([type isEqualToString:[OAOnlyImageViewCell getCellIdentifier]])
    {
        OAOnlyImageViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAOnlyImageViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAOnlyImageViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAOnlyImageViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        if (cell)
            cell.imageView.image = _downloadedImages.firstObject;
        return cell;
    }
    else if ([type isEqualToString:[OAImagesTableViewCell getCellIdentifier]])
    {
        OAImagesTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAImagesTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAImagesTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAImagesTableViewCell *)[nib objectAtIndex:0];;
        }
        if (cell)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
            cell.collectionViewWidth.constant = self.view.frame.size.width;
            cell.collectionViewHeight.constant = imageViewHeight;
            cell.images = _downloadedImages;
        }
        return cell;
    }
    else if ([type isEqualToString:[OAFilledButtonCell getCellIdentifier]])
    {
        OAFilledButtonCell* cell;
        cell = (OAFilledButtonCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAFilledButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.button.layer.cornerRadius = 9.;
            cell.topMarginConstraint.constant = 13.;
            cell.bottomMarginConstraint.constant = 13.;
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        if (cell)
        {
            OADownloadActionButton *button = item[@"button"];
            [cell.button setTitle:button.name forState:UIControlStateNormal];
            cell.button.tag = indexPath.row;
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:@selector(onActionPressed:) forControlEvents:UIControlEventTouchDown];
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OAImagesTableViewCell getCellIdentifier]])
        return imageViewHeight;
    return UITableViewAutomaticDimension;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.001;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

@end
