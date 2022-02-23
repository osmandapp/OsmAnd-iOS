//
//  OAMapillaryImageViewController.h
//  OsmAnd
//
//  Created by Paul on 21/05/19.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#define MAPILLARY_VIEWER_URL_TEMPLATE @"https://osmand.net/api/mapillary/photo-viewer?photo_id="
#define kDefaultMapillaryZoomOnShow 17.0f

@class OAMapillaryImage;

@interface OAMapillaryImageViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *noInternetView;
@property (weak, nonatomic) IBOutlet UILabel *noConnectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *noConnectionDescr;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;
@property (weak, nonatomic) IBOutlet UIImageView *noConnectionImageView;

- (void) showImage:(OAMapillaryImage *)image;
- (void) hideMapillaryView;

@end
