//
//  OAQLabelElement.m
//  OsmAnd
//
//  Created by Feschenko Fedor on 7/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAQLabelElement.h"

@implementation OAQLabelElement


- (instancetype)init {
    self = [super init];
    self.accessoryViewImage = nil;
    self.transform = CGAffineTransformIdentity;
    self.accessoryView = nil;
    return self;
}

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    UITableViewCell *cell = [super getCellForTableView:tableView controller:controller];
    [self setupAccessoryViewForCell:cell];
    return cell;
}

- (void)setupAccessoryViewForCell:(UITableViewCell *)cell
{
    if (_accessoryViewAllowed) {
        // If accessoryView id set for UITableViewCell - ignore accessoryType (see UITableViewCell.accessoryView)
        if (_accessoryView != nil)
            cell.accessoryView = _accessoryView;
        // If _accessoryView is not set and _accessoryViewImage is not nil than cell's accessoryView will be set as UIImageView
        else if (_accessoryViewImage != nil) {
            CIImage *image = _accessoryViewImage.CIImage;
            if (!image)
                image = [CIImage imageWithCGImage:_accessoryViewImage.CGImage];
            image = [image imageByApplyingTransform:_transform];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageWithCIImage:image]];
        }
    } else {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
