//
//  OAGPXImportUIHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 27/01/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol OAGPXImportUIHelperDelegate <NSObject>

- (void) updateDelegateVCData;

@end

@interface OAGPXImportUIHelper : NSObject

@property (nonatomic, weak) id<OAGPXImportUIHelperDelegate> delegate;

- (instancetype) initWithHostViewController:(UIViewController *)hostVC;

- (void)onImportClicked;
- (void)onImportClickedWithDestinationFolderPath:(NSString *)destPath;
- (void)prepareProcessUrl:(NSURL *)url showAlerts:(BOOL)showAlerts openGpxView:(BOOL)openGpxView completion:(void (^)(BOOL success))completion;

@end
