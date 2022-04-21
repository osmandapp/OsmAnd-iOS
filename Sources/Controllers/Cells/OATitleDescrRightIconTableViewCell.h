//
//  OATitleDescrRightIconTableViewCell.h
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 30.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OATitleDescrRightIconTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@end

NS_ASSUME_NONNULL_END
