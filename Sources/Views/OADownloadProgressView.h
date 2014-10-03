//
//  OADownloadProgressView.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 01.10.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OADownloadProgressViewDelegate;

@interface OADownloadProgressView : UIView

@property (weak, nonatomic) IBOutlet UIProgressView *progressBarView;
@property (weak, nonatomic) IBOutlet UIButton *startStopButtonView;
@property (strong, nonatomic) id<OADownloadProgressViewDelegate> delegate;
@property (strong, nonatomic) NSString* taskName;

-(void)setProgress:(float)progress;
-(void)setButtonStatePause;
-(void)setButtonStateResume;

@end


@protocol OADownloadProgressViewDelegate <NSObject>
- (void)resumeDownloadButtonClicked:(OADownloadProgressView *)view;
- (void)pauseDownloadButtonClicked:(OADownloadProgressView *)view;
@end