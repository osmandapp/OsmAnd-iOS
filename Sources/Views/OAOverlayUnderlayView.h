//
//  OAOverlayUnderlayView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    OAViewLayoutNone = 0,
    OAViewLayoutOverlayOnly,
    OAViewLayoutUnderlayOnly,
    OAViewLayoutOverlayUnderlay,
} OAViewLayout;

@interface OAOverlayUnderlayView : UIView

@property (weak, nonatomic) IBOutlet UIButton *btnExit;
@property (weak, nonatomic) IBOutlet UILabel *lbOverlay;
@property (weak, nonatomic) IBOutlet UISlider *slOverlay;
@property (weak, nonatomic) IBOutlet UILabel *lbUnderlay;
@property (weak, nonatomic) IBOutlet UISlider *slUnderlay;

@property (nonatomic, readonly) OAViewLayout viewLayout;

- (void)updateView;
- (CGFloat)getHeight:(CGFloat)width;

@end
