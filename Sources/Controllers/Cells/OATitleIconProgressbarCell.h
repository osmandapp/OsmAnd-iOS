//
//  OATitleIconProgressbarCell.h
//  OsmAnd
//
//  Created by Paul on 22/07/2022.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATitleIconProgressbarCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

@end
