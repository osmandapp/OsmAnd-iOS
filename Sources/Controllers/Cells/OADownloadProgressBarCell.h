//
//  OADownloadProgressBarCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OADownloadProgressBarCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIProgressView *progressBarView;
@property (weak, nonatomic) IBOutlet UILabel *progressStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressValueLabel;

- (void)showLabels:(BOOL)show;

@end
