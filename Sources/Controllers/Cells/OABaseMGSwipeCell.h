//
//  OABaseMGSwipeCell.h
//  OsmAnd
//
//  Created by nnngrach on 06.05.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

// This is superclass for all MGSwipeTable cells

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"

@interface OABaseMGSwipeCell : MGSwipeTableCell

- (NSString *) getCellIdentifier;

@end
