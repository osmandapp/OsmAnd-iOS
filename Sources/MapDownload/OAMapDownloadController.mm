//
//  OAMapDownloadController.m
//  OsmAnd
//
//  Created by Paul on 07.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAMapDownloadController.h"
#import "OADownloadedRegionsLayer.h"
#import "OAWorldRegion.h"
#import "OAResourcesUIHelper.h"
#import "Localization.h"

@interface OAMapDownloadController ()

@end

@implementation OAMapDownloadController
{
    OADownloadMapObject *_mapObject;
}

- (instancetype)initWithMapObject:(OADownloadMapObject *)downloadMapObject
{
    self = [super init];
    if (self)
    {
        _mapObject = downloadMapObject;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self applyTopToolbarTargetTitle];
}

- (void) applyTopToolbarTargetTitle
{
    if (self.delegate)
        self.titleView.text = [self.delegate getTargetTitle];
}

- (NSString *) getTypeStr
{
    return nil;
}

- (UIColor *) getAdditionalInfoColor
{
    return nil;
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return nil;
}

- (UIImage *) getAdditionalInfoImage
{
    return nil;
}

- (BOOL)showNearestPoi
{
    return NO;
}

- (BOOL)showNearestWiki
{
    return NO;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (BOOL)hideButtons
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFloating;
}

- (id) getTargetObj
{
    return _mapObject;
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    OAWorldRegion *region = _mapObject.worldRegion;
    OAResourceItem *item = _mapObject.indexItem;
    NSString *resTypeLocalized = [OAResourcesUIHelper resourceTypeLocalized:item.resourceType];
    NSString *iconInfo = @"ic_description.png";
    if (resTypeLocalized && resTypeLocalized.length > 0)
    {
        [rows addObject:[[OARowInfo alloc] initWithKey:region.name icon:[OATargetInfoViewController getIcon:iconInfo] textPrefix:nil text:resTypeLocalized textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO]];
    }
    [rows addObject:[[OARowInfo alloc] initWithKey:region.name icon:[OATargetInfoViewController getIcon:iconInfo] textPrefix:nil text:[NSByteCountFormatter stringFromByteCount:item.sizePkg countStyle:NSByteCountFormatterCountStyleFile] textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO]];
    if (region.wikiLink && region.wikiLink.length > 0)
    {
        NSArray<NSString *> *items = [region.wikiLink componentsSeparatedByString:@":"];
        NSString *url;
        if (items.count > 1)
            url = [NSString stringWithFormat:@"https://%@.wikipedia.org/wiki/%@", items[0], [items[1] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
        else
            url = [NSString stringWithFormat:@"https://wikipedia.org/wiki/%@", [items[0] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
        [rows addObject:[[OARowInfo alloc] initWithKey:region.name icon:[OATargetInfoViewController getIcon:iconInfo] textPrefix:nil text:url textColor:UIColorFromRGB(kHyperlinkColor) isText:NO needLinks:YES order:0 typeName:@"" isPhoneNumber:NO isUrl:YES]];
    }
    if (region.population && region.population.length > 0)
    {
        [rows addObject:[[OARowInfo alloc] initWithKey:region.name icon:[OATargetInfoViewController getIcon:iconInfo] textPrefix:nil text:[NSString stringWithFormat:OALocalizedString(@"population_num"), region.population] textColor:nil isText:YES needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:YES]];
    }
}

@end
