//
//  OADownloadProgressView.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 01.10.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadProgressView.h"

@interface OADownloadProgressView()

typedef enum {
    kDownloadProgressButtonStatePause = 0,
    kDownloadProgressButtonStateResume
} kDownloadProgressButtonState;

@property kDownloadProgressButtonState buttonState;

@end

@implementation OADownloadProgressView

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
            [self.progressBarView setProgress:0];
            self.buttonState = kDownloadProgressButtonStatePause;
            [self setButtonStatePause];
            
            // drop shadow
            [self.layer setShadowColor:[UIColor blackColor].CGColor];
            [self.layer setShadowOpacity:0.2];
            [self.layer setShadowRadius:2.0];
            [self.layer setShadowOffset:CGSizeMake(0.0, -1.5)];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
            [self.progressBarView setProgress:0];
            self.frame = frame;
            self.buttonState = kDownloadProgressButtonStatePause;
            [self setButtonStatePause];

            // drop shadow
            [self.layer setShadowColor:[UIColor blackColor].CGColor];
            [self.layer setShadowOpacity:0.2];
            [self.layer setShadowRadius:2.0];
            [self.layer setShadowOffset:CGSizeMake(0.0, -1.5)];
        }
    }
    return self;
}

-(void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self.delegate downloadProgressViewDidAppear:self];
}

-(void)setProgress:(float)progress {
    [self.progressBarView setProgress:progress];
}

-(void)setTitle:(NSString*)title {
    [self.titleView setText:title];
}

- (IBAction)startStopButtonClicked:(id)sender {
    
    if(self.buttonState == kDownloadProgressButtonStatePause) { // pause
        [self.delegate pauseDownloadButtonClicked:self];
        [self setButtonStateResume];
    }
    else {
        [self.delegate resumeDownloadButtonClicked:self];
        [self setButtonStatePause];
    }
}

-(void)setButtonStatePause {
    self.buttonState = kDownloadProgressButtonStatePause;
    [self.startStopButtonView setImage:[UIImage imageNamed:@"ic_custom_pause"] forState:UIControlStateNormal];
}

-(void)setButtonStateResume {
    self.buttonState = kDownloadProgressButtonStateResume;
    [self.startStopButtonView setImage:[UIImage imageNamed:@"ic_custom_play"] forState:UIControlStateNormal];
}


@end
