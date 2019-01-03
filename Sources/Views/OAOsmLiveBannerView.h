//
//  OAOsmLiveBanner.h
//  OsmAnd
//
//  Created by Alexey on 03/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    EOAOsmLiveBannerUnlockAll,
    EOAOsmLiveBannerUnlockUpdates
} EOAOsmLiveBannerType;

@protocol OAOsmLiveBannerViewDelegate <NSObject>

@required
- (void) osmLiveBannerPressed;

@end

@interface OAOsmLiveBannerView : UIView

@property (nonatomic, readonly) EOAOsmLiveBannerType bannerType;
@property (nonatomic, readonly) NSString *minPriceStr;

@property (nonatomic, weak) id<OAOsmLiveBannerViewDelegate> delegate;

+ (instancetype) bannerWithType:(EOAOsmLiveBannerType)bannerType minPriceStr:(NSString *)minPriceStr;
- (CGRect) updateFrame:(CGFloat)width margin:(CGFloat)margin;

@end

NS_ASSUME_NONNULL_END
