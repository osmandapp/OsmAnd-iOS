//
//  OAMapillaryImageCell.h
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OALabelViewWithInsets.h"

@interface OAImageCardCell : UICollectionViewCell


@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet OALabelViewWithInsets *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *logoView;

- (void) setUserName:(NSString *)username;

@end
