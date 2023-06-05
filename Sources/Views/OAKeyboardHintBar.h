//
//  OAKeyboardHintBar.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 30.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OAKeyboardHintBar;

@protocol OAKeyboardHintBarDelegate <NSObject>

- (void)keyboardHintBarDidTapButton;

@end

@interface OAKeyboardHintBar : UIView

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, weak) id<OAKeyboardHintBarDelegate> delegate;

@end
