//
//  QuickDialogTableView+ElementByIndexAccessor.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuickDialog.h>
#import <QuickDialogTableView.h>

@interface QuickDialogTableView (ElementByIndexAccessor)

- (QElement*)elementForIndexPath:(NSIndexPath*)indexPath;
- (NSArray*)elementsForIndexPaths:(NSArray*)indexPaths;

@end
