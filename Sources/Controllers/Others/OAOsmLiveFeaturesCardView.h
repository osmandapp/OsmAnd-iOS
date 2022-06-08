//
//  OAOsmLiveFeaturesCardView.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseFeatureCardView.h"
#import "OAFeatureCardRow.h"

NS_ASSUME_NONNULL_BEGIN

@class OAFeature;

@interface OAOsmLiveFeaturesCardView : OABaseFeatureCardView

- (OAFeatureCardRow *)addInfoRowWithFeature:(OAFeature *)feature selected:(BOOL)selected showDivider:(BOOL)showDivider;

@end

NS_ASSUME_NONNULL_END
