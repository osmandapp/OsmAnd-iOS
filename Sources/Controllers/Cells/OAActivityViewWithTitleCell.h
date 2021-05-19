//
//  OAActivityViewWithTitleCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 20.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAActivityViewWithTitleCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@end
