//
//  OABaseHeaderFooterCell.h
//  OsmAnd Maps
//
//  Created by nnngrach on 07.05.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

// This is superclass for all header/footer cells

#import <UIKit/UIKit.h>

@interface OABaseHeaderFooterCell : UITableViewHeaderFooterView

- (NSString *) getCellIdentifier;

@end
