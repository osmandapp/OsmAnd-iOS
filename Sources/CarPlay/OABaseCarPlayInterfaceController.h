//
//  OABaseCarPlayInterfaceController.h
//  OsmAnd Maps
//
//  Created by Paul on 12.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@class CPInterfaceController, CPListItem, CPListTemplate, CPListSection, CPTemplate, OAPointDescription;

typedef void (^OACarPlayTemplateCompletion)(BOOL completed, NSError * _Nullable error);

API_AVAILABLE(ios(12.0))
@interface OABaseCarPlayInterfaceController : NSObject

@property (nonatomic, readonly) CPInterfaceController *interfaceController;

- (instancetype) initWithInterfaceController:(CPInterfaceController *)interfaceController;

- (void) present;

- (void)safeSetRootTemplate:(CPTemplate *)cpTemplate animated:(BOOL)animated;
- (void)safePushTemplate:(CPTemplate *)cpTemplate animated:(BOOL)animated;
- (void)safePopTemplateAnimated:(BOOL)animated completion:(nullable OACarPlayTemplateCompletion)completion;
- (void)safePopToRootTemplateAnimated:(BOOL)animated;

- (void) startNavigationGivenLocation:(CLLocation *)loc historyName:(nullable OAPointDescription *)historyName;

- (NSArray<CPListSection *> *) generateSingleItemSectionWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
