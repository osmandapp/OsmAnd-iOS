//
//  OAOsmLiveFeaturesCardView.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmLiveFeaturesCardView.h"

#define kTextMargin 12.0
#define kDivH 0.5

@interface OAOsmLiveFeaturesCardView()

@property (weak, nonatomic) IBOutlet UIView *rowsContainer;


@end

@implementation OAOsmLiveFeaturesCardView

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAOsmLiveFeaturesCardView class]])
        {
            self = (OAOsmLiveFeaturesCardView *)v;
            break;
        }
    
    if (self)
        self.frame = CGRectMake(0, 0, 200, 100);
    
    [self commonInit];
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAOsmLiveFeaturesCardView class]])
        {
            self = (OAOsmLiveFeaturesCardView *)v;
            break;
        }
    
    if (self)
        self.frame = frame;
    
    [self commonInit];
    return self;
}

- (void) commonInit
{
}

- (CGFloat) updateLayout:(CGFloat)width
{
    CGFloat h = 0;
    CGFloat y = 0;
    CGRect cf = self.rowsContainer.frame;
    for (OAFeatureCardRow *row in self.rowsContainer.subviews)
    {
        y += [row updateFrame:y width:self.frame.size.width];
    }
    cf.size.width = width;
    cf.size.height = y;
    self.rowsContainer.frame = cf;
    h = y + cf.origin.y;
    h += kTextMargin;

    return h;
}

- (OAFeatureCardRow *)addInfoRowWithFeature:(OAFeature *)feature selected:(BOOL)selected showDivider:(BOOL)showDivider
{
    OAFeatureCardRow *row = [[OAFeatureCardRow alloc] initWithType:EOAFeatureCardRowSubscription];
    [row updateInfo:feature showDivider:showDivider selected:selected];
    [self.rowsContainer addSubview:row];
    return row;
}

@end
