//
//  OAPreviewZoomLevelsCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 26.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADownloadMapViewController.h"

@protocol OAPreviewZoomLevelsCellDelegate <NSObject>

- (void) toggleMinZoomPickerRow;
- (void) toggleMaxZoomPickerRow;

@end


@interface OAPreviewZoomLevelsCell : UITableViewCell

@property (nonatomic, weak) id<OAPreviewZoomLevelsCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *minLevelZoomButton;
@property (weak, nonatomic) IBOutlet UIButton *maxLevelZoomButton;
@property (weak, nonatomic) IBOutlet UIView *minLevelZoomView;
@property (weak, nonatomic) IBOutlet UIView *minZoomPropertyView;
@property (weak, nonatomic) IBOutlet UILabel *minZoomPropertyLabel;
@property (weak, nonatomic) IBOutlet UIView *maxLevelZoomView;
@property (weak, nonatomic) IBOutlet UIView *maxZoomPropertyView;
@property (weak, nonatomic) IBOutlet UILabel *maxZoomPropertyLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end
