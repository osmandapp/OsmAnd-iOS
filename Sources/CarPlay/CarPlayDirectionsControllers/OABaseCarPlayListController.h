//
//  OABaseCarPlayListController.h
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayInterfaceController.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const OACarPlayTemplatesDidChangeNotification;
FOUNDATION_EXPORT NSNotificationName const OACarPlayDidDisconnectNotification;

@interface OABaseCarPlayListController : OABaseCarPlayInterfaceController

@property (nonatomic, readonly) NSString *screenTitle;

- (void) updateSections:(NSArray<CPListSection *> *)sections;

// Called when this template leaves the navigation stack, or CarPlay disconnects.
- (void)onTemplateDismissed;

@end

NS_ASSUME_NONNULL_END
