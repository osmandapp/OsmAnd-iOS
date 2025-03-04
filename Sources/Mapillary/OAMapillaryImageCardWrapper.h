//
//  OAMapillaryImageCardWrapper.h
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAMapPanelViewController;

@interface OAMapillaryImageCardWrapper : NSObject

+ (void)onCardPressed:(OAMapPanelViewController *)mapPanel
             latitude:(CGFloat)latitude
            longitude:(CGFloat)longitude
                   ca:(CGFloat)ca
                  key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
