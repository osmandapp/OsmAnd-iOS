//
//  OAButtonMenuCell.h
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAButtonMenuCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *button;

-(void)showImage:(BOOL)show;

@end
