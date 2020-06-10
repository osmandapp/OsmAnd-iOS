//
//  OAPreviewZoomLevelsCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 26.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

@interface OAPreviewZoomLevelsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *minLevelZoomView;
@property (weak, nonatomic) IBOutlet UIView *minZoomPropertyView;
@property (weak, nonatomic) IBOutlet UILabel *minZoomPropertyLabel;
@property (weak, nonatomic) IBOutlet UIImageView *minZoomImageView;
@property (weak, nonatomic) IBOutlet UIView *maxLevelZoomView;
@property (weak, nonatomic) IBOutlet UIView *maxZoomPropertyView;
@property (weak, nonatomic) IBOutlet UILabel *maxZoomPropertyLabel;
@property (weak, nonatomic) IBOutlet UIImageView *maxZoomImageView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end
