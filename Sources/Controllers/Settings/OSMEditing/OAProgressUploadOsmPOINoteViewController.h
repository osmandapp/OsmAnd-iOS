//
//  OAProgressUploadOsmPOINoteViewController.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 24.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseButtonsViewController.h"

@class OAOsmPoint;

@protocol OAProgressUploadDelegate <NSObject>

@required
- (void)retryUpload;
- (void)dismissViewController;

@end

@interface OAProgressUploadOsmPOINoteViewController : OABaseButtonsViewController

@property (nonatomic) id<OAProgressUploadDelegate> delegate;

- (void)setProgress:(float)progress;
- (void)setUploadResultWithFailedPoints:(NSArray<OAOsmPoint *> *)points successfulUploads:(NSInteger)successfulUploads;
- (instancetype)initWithParam:(id)param;

@end
