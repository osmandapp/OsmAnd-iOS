//
//  OAMapillaryImageCell.h
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAMapillaryImageCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *mapillaryImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

- (void) setUserName:(NSString *)username;

@end
