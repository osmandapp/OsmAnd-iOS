//
//  OADownloadProgressView.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 01.10.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kOADownloadProgressViewHeight 45

@protocol OADownloadProgressViewDelegate;

@interface OADownloadProgressView : UIView

@property (weak, nonatomic) IBOutlet UIProgressView *progressBarView;
@property (weak, nonatomic) IBOutlet UIButton *startStopButtonView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;

@property (strong, nonatomic) id<OADownloadProgressViewDelegate> delegate;
@property (strong, nonatomic) NSString* taskName;

-(void)setProgress:(float)progress;
-(void)setTitle:(NSString*)title;
-(void)setButtonStatePause;
-(void)setButtonStateResume;

@end


@protocol OADownloadProgressViewDelegate <NSObject>

- (void)resumeDownloadButtonClicked:(OADownloadProgressView *)view;
- (void)pauseDownloadButtonClicked:(OADownloadProgressView *)view;

- (void)downloadProgressViewDidAppear:(OADownloadProgressView *)view;
- (void)downloadProgressViewDidDisappear:(OADownloadProgressView *)view;

@end