//
//  OAOsmLiveFeaturesCardView.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmLiveFeaturesCardView.h"
#import "OAPurchaseDialogCardRow.h"
#import "OAPurchaseDialogCardButton.h"
#import "OAColors.h"

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
    for (OAPurchaseDialogCardRow *row in self.rowsContainer.subviews)
    {
        CGRect rf = [row updateFrame:width];
        rf.origin.y = y;
        row.frame = rf;
        y += rf.size.height;
    }
    cf.size.width = width;
    cf.size.height = y;
    self.rowsContainer.frame = cf;
    h = y + cf.origin.y;
    h += kTextMargin;

    return h;
}

- (OAPurchaseDialogCardRow *) addInfoRowWithText:(NSString *)text image:(UIImage *)image selected:(BOOL)selected showDivider:(BOOL)showDivider
{
    return [self addInfoRowWithText:text textColor:[UIColor blackColor] image:image selected:selected showDivider:showDivider];
}

- (OAPurchaseDialogCardRow *) addInfoRowWithText:(NSString *)text textColor:(UIColor *)color image:(UIImage *)image selected:(BOOL)selected showDivider:(BOOL)showDivider
{
    OAPurchaseDialogCardRow *row = [[OAPurchaseDialogCardRow alloc] initWithFrame:CGRectMake(0, 0, 100, 54)];
    [row setText:text textColor:color image:image selected:selected showDivider:showDivider];
    [self.rowsContainer addSubview:row];
    return row;
}

@end
