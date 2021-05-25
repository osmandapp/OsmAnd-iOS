//
//  OARendererRegistry.m
//  OsmAnd Maps
//
//  Created by Paul on 20.05.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARendererRegistry.h"
#import "OsmAndApp.h"
#import "OAIndexConstants.h"

@implementation OARendererRegistry

+ (NSArray<NSString *> *) getExternalRenderers
{
    NSMutableArray<NSString *> *res = [NSMutableArray array];
    [self fetchExternalRenderers:OsmAndApp.instance.documentsPath acceptedItems:res];
    return res;
}

+ (void) fetchExternalRenderers:(NSString *)basePath acceptedItems:(NSMutableArray<NSString *> *)acceptedItems
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSArray<NSString *> *items = [fileManager contentsOfDirectoryAtPath:basePath error:nil];
    for (NSString *item in items)
    {
        if ([item hasSuffix:RENDERER_INDEX_EXT])
            [acceptedItems addObject:[basePath stringByAppendingPathComponent:item]];
        else if ([item isEqualToString:RENDERERS_DIR])
            [self fetchExternalRenderers:[basePath stringByAppendingPathComponent:item] acceptedItems:acceptedItems];
    }
}

@end
