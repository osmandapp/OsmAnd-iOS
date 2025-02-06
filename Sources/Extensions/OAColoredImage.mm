//
//  OAColoredImage.mm
//  OsmAnd
//
//  Created by Max Kojin on 06/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAColoredImage.h"
#import "OsmAndApp.h"
#import "OAObserverProtocol.h"
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"

@implementation OAColoredImage

- (instancetype)initWithImage:(UIImage *)image color:(UIColor *)color
{
    self = [super initWithCGImage:image.CGImage scale:image.scale orientation:image.imageOrientation];
    if (self)
        _color = color;
    return self;
}

- (instancetype)initWithName:(NSString *)name color:(UIColor *)color
{
    UIImage *image = [OAUtilities imageWithTintColor:color image:[UIImage imageNamed:name]];
    self = [self initWithImage:image color:color];
    return self;
}

@end


@implementation OAColoredImageView
{
    OsmAndAppInstance _app;
    OAAutoObserverProxy *_observer;
}

- (instancetype)init
{
    self = [super init];
    if (self)
        [self commonInit];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
        [self commonInit];
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super initWithImage:image];
    if (self)
        [self commonInit];
    return self;
}

- (instancetype)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage
{
    self = [super initWithImage:image highlightedImage:highlightedImage];
    if (self)
        [self commonInit];
    return self;
}

- (void) commonInit
{
    _observer = [[OAAutoObserverProxy alloc] initWith:self
                                          withHandler:@selector(updateAppeance)
                                           andObserve:[OsmAndApp instance].appearanceChangeObservable];
}

- (void) updateAppeance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.image && [self.image isKindOfClass:OAColoredImage.class])
        {
            OAColoredImage *coloredImage = (OAColoredImage *)self.image;
            if (coloredImage.color)
            {
                UIImage *recoloredImage = [OAUtilities imageWithTintColor:coloredImage.color image:coloredImage];
                self.image = [[OAColoredImage alloc] initWithImage:recoloredImage color:coloredImage.color];
            }
        }
    });
}

@end
