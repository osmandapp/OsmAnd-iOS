//
//  QuickDialogTableView+ElementByIndexAccessor.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "QuickDialogTableView+ElementByIndexAccessor.h"

@implementation QuickDialogTableView (ElementByIndexAccessor)

- (QElement*)elementForIndexPath:(NSIndexPath*)indexPath
{
    for (QSection* section in self.root.sections)
    {
        for (QElement* element in section.elements)
        {
            NSIndexPath* otherIndexPath = [element getIndexPath];
            if ([otherIndexPath isEqual:indexPath])
                return element;
        }
    }

    return nil;
}

- (NSArray*)elementsForIndexPaths:(NSArray*)indexPaths
{
    NSMutableArray* result = [NSMutableArray array];

    for (QSection* section in self.root.sections)
    {
        for (QElement* element in section.elements)
        {
            NSIndexPath* otherIndexPath = [element getIndexPath];

            for (NSIndexPath* indexPath in indexPaths)
            {
                if ([otherIndexPath isEqual:indexPath])
                    [result addObject:element];
            }
        }
    }

    return [result copy];
}

@end
