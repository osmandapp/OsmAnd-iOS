//
//  OAWikiMenuViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAWikiMenuViewController.h"
#import "OAPOI.h"
#import "OAAmenitySearcher.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static const NSInteger kOrderContentRow = 1;

@interface OAWikiMenuViewController ()<OARowInfoDelegate>

@end

@implementation OAWikiMenuViewController
{
    NSString *_content;
}

- (id)initWithPOI:(OAPOI *)poi content:(NSString *)content
{
    self = [super initWithPOI:poi];
    if (self)
    {
        _content = content;
        OAAmenityInfoRow* contentRow = [[OAAmenityInfoRow alloc] initWithKey:nil icon:[OATargetInfoViewController getIcon:@"ic_description.png"] textPrefix:nil text:content textColor:nil isText:YES needLinks:NO order:kOrderContentRow typeName:@"" isPhoneNumber:NO isUrl:NO];
        contentRow.isHtml = YES;
        contentRow.delegate = self;
        if (contentRow.isText && !NSStringIsEmpty(contentRow.text))
            self.additionalRows = @[contentRow];
        self.leftControlButton = nil;
        self.rightControlButton = nil;
        self.downloadControlButton = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    OAPOI *sourcePoi = self.poi;
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        BaseDetailsObject *detailsObject = [OAAmenitySearcher.sharedInstance searchDetailedObject:sourcePoi];

        if (!detailsObject)
            return;
        [detailsObject addObject:sourcePoi];

        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || !strongSelf.viewIfLoaded.window || strongSelf.poi != sourcePoi)
                return;

            [strongSelf setup:detailsObject.syntheticAmenity];
            [strongSelf rebuildRows];
            [strongSelf.tableView reloadData];
            [strongSelf.delegate refreshTargetPointHeader];
        });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) leftControlButtonPressed
{
    if ([self.menuDelegate respondsToSelector:@selector(openWiki:)])
        [self.menuDelegate openWiki:self];
}

#pragma mark - OARowInfoDelegate

- (void)onRowClick:(OATargetMenuViewController *)sender rowInfo:(OAAmenityInfoRow *)rowInfo
{
    if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(openWiki:)])
        [self.menuDelegate openWiki:self];
}

@end
