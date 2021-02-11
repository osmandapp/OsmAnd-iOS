//
//  OACarPlaySceneDelegate.h
//  OsmAnd
//
//  Created by Paul on 09.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CarPlay/CarPlay.h>

@interface OACarPlaySceneDelegate : NSObject <CPTemplateApplicationSceneDelegate>

@property (nonatomic, readonly) CPInterfaceController* interfaceController;

@end
