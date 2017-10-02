//
//  OATextInfoWidget.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol OAWidgetListener <NSObject>

@required
- (void) widgetVisibilityChanged:(BOOL)visible;
- (void) widgetClicked:(id)sender;

@end

@interface OATextInfoWidget : UIView

@property (nonatomic, weak) id<OAWidgetListener> delegate;

- (void) setImage:(UIImage *)image;
- (void) setTopImage:(UIImage *)image;
- (BOOL) isNight;
- (BOOL) setIcons:(NSString *)widgetDayIcon widgetNightIcon:(NSString *)widgetNightIcon;

- (BOOL) isNight;
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
