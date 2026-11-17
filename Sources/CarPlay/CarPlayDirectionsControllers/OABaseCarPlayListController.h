//
//  OABaseCarPlayListController.h
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayInterfaceController.h"

NS_ASSUME_NONNULL_BEGIN

@class OABaseCarPlayListController;

@protocol OACarPlayListLifecycleDelegate <NSObject>
- (void)registerListController:(OABaseCarPlayListController *)controller;
@end

@interface OABaseCarPlayListController : OABaseCarPlayInterfaceController

@property (nonatomic, readonly) NSString *screenTitle;
@property (nonatomic, readonly, nullable) CPListTemplate *listTemplate;

- (void) updateSections:(NSArray<CPListSection *> *)sections;

- (void)dismissTemplate;

// Called when this template leaves the navigation stack, or CarPlay disconnects.
- (void)onTemplateDismissed;

@end

NS_ASSUME_NONNULL_END
