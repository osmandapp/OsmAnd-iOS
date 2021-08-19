//
//  OAWikiMenuViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAWikiMenuViewController.h"
#import "OAPOI.h"

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
        OARowInfo* contentRow = [[OARowInfo alloc] initWithKey:nil icon:[OATargetInfoViewController getIcon:@"ic_description.png"] textPrefix:nil text:content textColor:nil isText:YES needLinks:NO order:1 typeName:@"" isPhoneNumber:NO isUrl:NO];
        contentRow.isHtml = YES;
        contentRow.delegate = self;
        self.additionalRows = @[contentRow];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - OARowInfoDelegate

- (void)onRowClick:(OATargetMenuViewController *)sender rowInfo:(OARowInfo *)rowInfo
{
    if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(openWiki:)])
        [self.menuDelegate openWiki:self];
}

@end

