//
//  OACollapsableTransportStopRoutesView.m
//  OsmAnd
//
//  Created by Alexey on 13/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACollapsableTransportStopRoutesView.h"
#import "OATransportStopViewController.h"
#import "OATransportStopRoute.h"
#import "OAColors.h"
#import "OARootViewController.h"
#import "OAMapLayers.h"
#import "OANativeUtilities.h"
#import "OATransportRouteController.h"

#define kTransportIconWidth 16.0

@interface OACollapsableTransportStopRoutesView () <OAButtonDelegate>

@end

@implementation OACollapsableTransportStopRoutesView
{
    NSArray<OAButton *> *_buttons;
    NSInteger _selectedButtonIndex;
}

- (void) setRoutes:(NSArray<OATransportStopRoute *> *)routes
{
    _routes = routes;
    [self buildViews];
}

- (void) buildViews
{
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:self.routes.count];
    int k = 0;

    for (OATransportStopRoute *route in self.routes)
    {
        NSString *text = [route getDescription:YES];
        text = [text stringByAppendingString:[NSString stringWithFormat:@"\n<img> %@", [route getTypeStr]]];

        NSString *resId = route.type.topResId;
        UIImage *img;
        if (resId.length > 0)
            img = [UIImage imageNamed:[OAUtilities drawablePath:resId]];
        if (!img)
            img = [OATargetInfoViewController getIcon:@"mx_public_transport"];
        
        img = [OAUtilities resizeImage:img newSize:{ kTransportIconWidth, kTransportIconWidth }];
        img = [OAUtilities getTintableImage:img];

        NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:text attributes:nil];

        int imgIndex = [text indexOf:@"<img>"];
        if (imgIndex != -1)
        {
            UIColor *titleColor = UIColorFromRGB(color_ctx_menu_bottom_view_text_color_light);
            UIColor *imgColor = UIColorFromRGB(color_ctx_menu_bottom_view_icon_light);
            UIColor *descrColor = UIColorFromARGB(color_secondary_text_light_argb);
            [title addAttribute:NSForegroundColorAttributeName value:titleColor range:NSMakeRange(0, imgIndex - 1)];
            [title addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0] range:NSMakeRange(0, imgIndex - 1)];
            
            int i = 0;
            for (;;)
            {
                int a = [text indexOf:OATransportStopRouteArrow start:i];
                if (a != -1)
                {
                    [title addAttribute:NSForegroundColorAttributeName value:imgColor range:NSMakeRange(a, OATransportStopRouteArrow.length)];
                    i = a + 1;
                }
                if (a == -1 || a >= text.length - 1)
                    break;
            }
            
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = img;
            NSAttributedString *strWithImage = [NSAttributedString attributedStringWithAttachment:attachment];
            [title replaceCharactersInRange:NSMakeRange(imgIndex, 5) withAttributedString:strWithImage];
            [title addAttribute:NSForegroundColorAttributeName value:imgColor range:NSMakeRange(imgIndex - 1, strWithImage.length + 1)];
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.minimumLineHeight = 30.;
            [title addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(imgIndex - 1, strWithImage.length + 1)];
            
            [title addAttribute:NSForegroundColorAttributeName value:descrColor range:NSMakeRange(imgIndex + strWithImage.length, title.length - imgIndex - strWithImage.length)];
            [title addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13.0] range:NSMakeRange(imgIndex + strWithImage.length, title.length - imgIndex - strWithImage.length)];
            [title addAttribute:NSBaselineOffsetAttributeName value:@(3.0) range:NSMakeRange(imgIndex + strWithImage.length, title.length - imgIndex - strWithImage.length)];
        }
        
        UIImage *stopPlate = [OATransportStopViewController createStopPlate:[OATransportStopViewController adjustRouteRef:route.route->ref.toNSString()] color:[route getColor:NO]];
        stopPlate = [stopPlate imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

        OAButton *btn = [OAButton buttonWithType:UIButtonTypeSystem];
        [btn setAttributedTitle:title forState:UIControlStateNormal];
        [btn setImage:stopPlate forState:UIControlStateNormal];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, kMarginLeft - kMarginRight, 0, 0);
        btn.imageEdgeInsets = UIEdgeInsetsMake(2, 0, 0, 0);
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, kMarginLeft - kMarginRight - stopPlate.size.width, 0, 0);
        btn.contentEdgeInsets = UIEdgeInsetsMake(kMarginTop, kMarginRight + [OAUtilities getLeftMargin], kMarginTop, kMarginRight);

        btn.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        //btn.layer.borderWidth = 0.5;
        btn.tag = k++;
        btn.delegate = self;
        btn.frame = {0, 320, 0, 56};
        [self addSubview:btn];
        [buttons addObject:btn];
    }
    _buttons = [NSArray arrayWithArray:buttons];
}

- (void) updateLayout:(CGFloat)width
{
    CGFloat viewHeight = 0;
    for (OAButton *btn in _buttons)
    {
        CGFloat labelWidth = width - [OAUtilities getLeftMargin] - kMarginLeft - kMarginRight;
        CGFloat h = [btn.currentAttributedTitle boundingRectWithSize:{labelWidth, 10000} options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) context:nil].size.height;
        CGFloat btnH = h + kMarginTop * 2;
        btn.contentEdgeInsets = UIEdgeInsetsMake(kMarginTop, kMarginRight + [OAUtilities getLeftMargin], kMarginTop, kMarginRight);

        btn.frame = CGRectMake(0, viewHeight, width, btnH);
        viewHeight += btn.bounds.size.height + 0.5;
    }
    viewHeight += 0.5;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, viewHeight);
}

- (void) adjustHeightForWidth:(CGFloat)width
{
    [self updateLayout:width];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return [sender isKindOfClass:UIMenuController.class] && action == @selector(copy:);
}

- (void)copy:(id)sender
{
    if (_buttons.count > _selectedButtonIndex)
    {
        OAButton *button = _buttons[_selectedButtonIndex];
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:button.titleLabel.text];
    }
}

#pragma mark - OACustomButtonDelegate

- (void)onButtonTapped:(NSInteger)tag
{
    if (self.routes.count > tag)
    {
        OATransportStopRoute *r = self.routes[tag];
        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
        OAMapViewController *mapController = mapPanel.mapViewController;

        OATargetPoint *targetPoint = [OATransportRouteController getTargetPoint:r];
        CLLocationCoordinate2D latLon = targetPoint.location;

        Point31 point31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.latitude, latLon.longitude))];
        [mapPanel prepareMapForReuse:point31 zoom:12 newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
        [mapController.mapLayers.transportStopsLayer showStopsOnMap:r];

        [mapPanel showContextMenuWithPoints:@[targetPoint]];

        [OATransportRouteController showToolbar:r];
    }
}

- (void)onButtonLongPressed:(NSInteger)tag
{
    _selectedButtonIndex = tag;
    if (_buttons.count > _selectedButtonIndex)
        [OAUtilities showMenuInView:self fromView:_buttons[_selectedButtonIndex]];
}

@end
