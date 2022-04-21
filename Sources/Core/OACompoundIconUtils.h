//
//  OACompoundIconUtils.h
//  OsmAnd Maps
//
//  Created by Paul on 21.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#include <OsmAndCore.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/GpxDocument.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/SkiaUtilities.h>

@interface OACompoundIconUtils : NSObject

+ (sk_sp<SkImage>) createCompositeBitmapFromWpt:(const OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> &)point isFullSize:(BOOL)isFullSize;
+ (sk_sp<SkImage>) createCompositeBitmapFromFavorite:(const std::shared_ptr<OsmAnd::IFavoriteLocation> &)fav isFullSize:(BOOL)isFullSize;
+ (sk_sp<SkImage>) createCompositeIconWithcolor:(UIColor *)color shapeName:(NSString *)shapeName iconName:(NSString *)iconName isFullSize:(BOOL)isFullSize icon:(UIImage *)icon;

@end
