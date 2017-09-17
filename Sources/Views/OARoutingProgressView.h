//
//  OARoutingProgressView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OARoutingProgressView : UIView

@property (weak, nonatomic) IBOutlet UIProgressView *progressBarView;

- (void) setProgress:(float)progress;

@end
