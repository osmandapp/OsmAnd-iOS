//
//  OAOsmUploadGPXVisibilityViewConroller.h
//  OsmAnd
//
//  Created by nnngrach on 01.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

typedef NS_ENUM(NSInteger, EOAOsmUploadGPXVisibility) {
    EOAOsmUploadGPXVisibilityPublic = 0,
    EOAOsmUploadGPXVisibilityIdentifiable,
    EOAOsmUploadGPXVisibilityTrackable,
    EOAOsmUploadGPXVisibilityPrivate
};


@protocol OAOsmUploadGPXVisibilityDelegate <NSObject>

@required

- (void)onVisibilityChanged:(EOAOsmUploadGPXVisibility)visibility;

@end


@interface OAOsmUploadGPXVisibilityViewConroller : OABaseNavbarViewController

@property (nonatomic, weak) id<OAOsmUploadGPXVisibilityDelegate> visibilityDelegate;

- (instancetype) initWithVisibility:(EOAOsmUploadGPXVisibility)visibility;

+ (NSString *) localizedNameForVisibilityType:(EOAOsmUploadGPXVisibility)visibility;
+ (NSString *) toUrlParam:(EOAOsmUploadGPXVisibility)visibility;

@end
