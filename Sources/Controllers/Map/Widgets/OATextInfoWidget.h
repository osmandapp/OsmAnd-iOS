//
//  OATextInfoWidget.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class OATextInfoWidget;

@protocol OAWidgetListener <NSObject>

@required
- (void) widgetChanged:(OATextInfoWidget *)widget;
- (void) widgetVisibilityChanged:(OATextInfoWidget *)widget visible:(BOOL)visible;
- (void) widgetClicked:(OATextInfoWidget *)widget;

@end

@interface OATextInfoWidget : UIView

@property (nonatomic, weak) id<OAWidgetListener> delegate;

- (void) setImage:(UIImage *)image;
- (void) setTopImage:(UIImage *)image;
- (BOOL) isNight;
- (BOOL) setIcons:(NSString *)widgetDayIcon widgetNightIcon:(NSString *)widgetNightIcon;

- (void) setContentDescription:(NSString *)text;
- (void) setContentTitle:(NSString *)text;
- (void) setText:(NSString *)text subtext:(NSString *)subtext;
- (BOOL) isVisible;
- (BOOL) updateInfo;
- (BOOL) isExplicitlyVisible;
- (void) setExplicitlyVisible:(BOOL)explicitlyVisible;
- (void) updateIconMode:(BOOL)night;
- (void) updateTextColor:(UIColor *)textColor bold:(BOOL)bold;

@end
