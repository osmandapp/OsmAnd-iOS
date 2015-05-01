//
//  InfoWidgetsView.h
//  OsmAnd DVR
//
//  Created by Alexey Kulish on 15/04/15.
//
//

#import <UIKit/UIKit.h>

@protocol InfoWidgetsViewDelegate <NSObject>

@optional
- (void) infoSelectPressed;

@end

@interface InfoWidgetsView : UIView

@property (nonatomic, strong) IBOutlet UIView *viewGpxRecWidget;
@property (nonatomic, strong) IBOutlet UIImageView *iconGpxRecWidget;
@property (nonatomic, strong) IBOutlet UILabel *lbGpxRecWidget;

@property (nonatomic, weak) id<InfoWidgetsViewDelegate> delegate;

- (void)updateGpxRec;

@end
