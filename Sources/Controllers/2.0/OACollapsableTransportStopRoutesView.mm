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
#import "OATransportStopType.h"
#import "OAUtilities.h"
#import "OAColors.h"

@implementation OACollapsableTransportStopRoutesView
{
    NSArray<UIButton *> *_buttons;
}

- (void) setRoutes:(NSArray<OATransportStopRoute *> *)routes
{
    _routes = routes;
    [self buildViews];
}

- (void) buildViews
{
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:self.routes.count];
    int i = 0;
    NSArray<NSString *> *arrowChars = @[@"=>", @" - "];
    NSString *arrow = @" → ";

    for (OATransportStopRoute *route in self.routes)
    {
        NSString *text = [route getDescription:YES];
        for (NSString *arrowChar in arrowChars)
            text = [text stringByReplacingOccurrencesOfString:arrowChar withString:arrow];
        
        text = [text stringByAppendingString:[NSString stringWithFormat:@"\n<img> %@", [route getTypeStr]]];

        NSString *resId = route.type.topResId;
        UIImage *img;
        if (resId.length > 0)
            img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/%@.png", [OAUtilities drawablePostfix], resId]];
        if (!img)
            img = [OATargetInfoViewController getIcon:@"mx_public_transport.png"];
        
        CGFloat imgSize = [[UIScreen mainScreen] scale] * 8.0;
        img = [OAUtilities resizeImage:img newSize:{ imgSize, imgSize }];
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
                int a = [text indexOf:arrow start:i];
                if (a != -1)
                {
                    [title addAttribute:NSForegroundColorAttributeName value:imgColor range:NSMakeRange(a, arrow.length)];
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
            [title addAttribute:NSBaselineOffsetAttributeName value:@(-8.0) range:NSMakeRange(imgIndex - 1, strWithImage.length + 1)];

            [title addAttribute:NSForegroundColorAttributeName value:descrColor range:NSMakeRange(imgIndex + strWithImage.length, title.length - imgIndex - strWithImage.length)];
            [title addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13.0] range:NSMakeRange(imgIndex + strWithImage.length, title.length - imgIndex - strWithImage.length)];
            [title addAttribute:NSBaselineOffsetAttributeName value:@(-6.0) range:NSMakeRange(imgIndex + strWithImage.length, title.length - imgIndex - strWithImage.length)];
        }
        
        UIImage *stopPlate = [OATransportStopViewController createStopPlate:[self adjustRouteRef:route.route->ref.toNSString()] color:[route getColor:NO]];
        stopPlate = [stopPlate imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setAttributedTitle:title forState:UIControlStateNormal];
        [btn setImage:stopPlate forState:UIControlStateNormal];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, kMarginLeft - kMarginRight, 0, 0);
        btn.imageEdgeInsets = UIEdgeInsetsMake(2, 0, 0, 0);
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, kMarginLeft - kMarginRight - stopPlate.size.width, 0, 0);
        btn.contentEdgeInsets = UIEdgeInsetsMake(kMarginTop, kMarginRight, kMarginTop, kMarginRight);

        btn.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        //btn.layer.borderWidth = 0.5;
        btn.tag = i++;
        //[btn addTarget:self action:@selector(btnPress:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = {0, 320, 0, 56};
        [self addSubview:btn];
        [buttons addObject:btn];
    }
    _buttons = [NSArray arrayWithArray:buttons];
}

- (NSString *) adjustRouteRef:(NSString *)ref
{
    if (ref)
    {
        int charPos = [ref lastIndexOf:@":"];
        if (charPos != -1)
            ref = [ref substringToIndex:charPos];
        
        if (ref.length > 4)
            ref = [ref substringToIndex:4];
    }
    return ref;
}

- (void) updateLayout:(CGFloat)width
{
    CGFloat viewHeight = 0;
    for (UIButton *btn in _buttons)
    {
        CGFloat h = [btn.currentAttributedTitle boundingRectWithSize:{width - kMarginLeft - kMarginRight, 10000} options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) context:nil].size.height;
        CGFloat btnH = h + kMarginTop * 2;

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

@end
