//
//  OAOsmLiveCardView.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAOsmLiveCardView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UIView *rowsContainer;
@property (weak, nonatomic) IBOutlet UILabel *lbButtonsDescription;
@property (weak, nonatomic) IBOutlet UIView *buttonsContainer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressView;

@end

NS_ASSUME_NONNULL_END
