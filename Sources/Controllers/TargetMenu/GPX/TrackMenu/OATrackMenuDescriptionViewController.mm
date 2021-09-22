//
//  OATrackMenuDescriptionViewController.mm
//  OsmAnd
//
// Created by Skalii on 22.09.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuDescriptionViewController.h"
#import "OATextViewSimpleCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAGPXDocument.h"
#import "OAGPXDatabase.h"

@interface OATrackMenuDescriptionViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation OATrackMenuDescriptionViewController
{
    NSString *_description;
    OAGPX *_gpx;
    OAGPXDocument *_doc;
    NSArray *_data;
}

- (instancetype)initWithGpxDoc:(OAGPXDocument *)doc gpx:(OAGPX *)gpx
{
    self = [super init];
    if (self)
    {
        _doc = doc;
        _gpx = gpx;
        _description = doc.metadata.desc;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self generateData];
}

- (void)applyLocalization
{
    self.titleLabel.text = [_gpx getNiceTitle];
    [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void)generateData
{
    NSMutableArray *data = [NSMutableArray array];

    [data addObject:@{
            @"type": [OATextViewSimpleCell getCellIdentifier],
            @"key": @"description"
    }];

    _data = data;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}

- (IBAction)onBackButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];

    UITableViewCell *outCell = nil;
    if ([item[@"type"] isEqualToString:[OATextViewSimpleCell getCellIdentifier]])
    {
        OATextViewSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextViewSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextViewSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OATextViewSimpleCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            NSAttributedString *description = [OAUtilities createAttributedString:_description
                                                                             font:[UIFont systemFontOfSize:17]
                                                                            color:[UIColor blackColor]
                                                                      strokeColor:nil
                                                                      strokeWidth:0
                                                                        alignment:NSTextAlignmentNatural];

            cell.textView.attributedText = description;
            cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple)};
            [cell.textView sizeToFit];
        }
        outCell = cell;
    }

    return outCell;
}

@end
