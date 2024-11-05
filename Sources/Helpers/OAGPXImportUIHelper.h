//
//  OAGPXImportUIHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 27/01/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Sent when the GPX file has been fully imported.
FOUNDATION_EXPORT NSNotificationName const OAGPXImportUIHelperDidFinishImportNotification;

@interface OAGPXImportUIHelper : NSObject

- (instancetype)initWithHostViewController:(UIViewController *)hostVC;

- (void)onImportClicked;
- (void)onImportClickedWithDestinationFolderPath:(NSString *_Nullable)destPath;
- (void)prepareProcessUrl:(NSURL *)url
               showAlerts:(BOOL)showAlerts
              openGpxView:(BOOL)openGpxView
               completion:(void (^ _Nullable)(BOOL success))completion;

NS_ASSUME_NONNULL_END

@end
