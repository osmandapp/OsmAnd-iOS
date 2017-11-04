//
//  OATextInfoWidget.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define kTextInfoWidgetWidth 94
#define kTextInfoWidgetHeight 32

@class OATextInfoWidget;

@protocol OAWidgetListener <NSObject>

@required
- (void) widgetChanged:(OATextInfoWidget *)widget;
- (void) widgetVisibilityChanged:(OATextInfoWidget *)widget visible:(BOOL)visible;
- (void) widgetClicked:(OATextInfoWidget *)widget;

@end

@interface OATextInfoWidget : UIView

@property (nonatomic, readonly) UIFont *primaryFont;
@property (nonatomic, readonly) UIColor *primaryColor;
@property (nonatomic, readonly) UIFont *unitsFont;
@property (nonatomic, readonly) UIColor *unitsColor;

@property (nonatomic, weak) id<OAWidgetListener> delegate;

@property (strong) BOOL(^updateInfoFunction)();
@property (strong) void(^onClickFunction)(id sender);

- (void) setImage:(UIImage *)image;
- (void) setImageHidden:(BOOL)visible;
- (BOOL) isNight;
- (BOOL) setIcons:(NSString *)widgetDayIcon widgetNightIcon:(NSString *)widgetNightIcon;

- (void) setContentDescription:(NSString *)text;
- (void) setContentTitle:(NSString *)text;
- (void) setText:(NSString *)text subtext:(NSString *)subtext;
- (BOOL) updateVisibility:(BOOL)visible;
- (BOOL) isVisible;
- (BOOL) updateInfo;
- (BOOL) isExplicitlyVisible;
- (void) setExplicitlyVisible:(BOOL)explicitlyVisible;
- (void) updateIconMode:(BOOL)night;
- (void) updateTextColor:(UIColor *)textColor bold:(BOOL)bold;

- (void) adjustViewSize;

@end
