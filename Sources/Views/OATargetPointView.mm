//
//  OATargetPointView.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 03.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATargetPointView.h"
#import "OsmAndApp.h"
#import "OAFavoriteItemViewController.h"
#import "OAMapRendererView.h"

@interface OATargetPointView()
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;

@property (weak, nonatomic) IBOutlet UIButton *buttonFavorite;
@property (weak, nonatomic) IBOutlet UIButton *buttonShare;
@property (weak, nonatomic) IBOutlet UIButton *buttonDirection;

@property double lat;
@property double lon;
@property CGPoint touchPoint;
@property NSString* formattedLocation;
@property OAMapRendererView* mapView;
@property UINavigationController* navController;

@end

@implementation OATargetPointView

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
            self.frame = frame;
        }
    }
    return self;
}


-(void)awakeFromNib {
    
    // drop shadow
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowOpacity:0.8];
    [self.layer setShadowRadius:3.0];
    [self.layer setShadowOffset:CGSizeMake(2.0, 2.0)];
}

-(void)setAddress:(NSString*)address {
    [self.addressLabel setText:address];
}

-(void)setPointLat:(double)lat Lon:(double)lon andTouchPoint:(CGPoint)touchPoint {
    self.lat = lat;
    self.lon = lon;
    self.touchPoint = touchPoint;

    self.formattedLocation = [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:CLLocationCoordinate2DMake(lat, lon)];
    [self.coordinateLabel setText:self.formattedLocation];
}

-(void)setMapViewInstance:(UIView*)mapView {
    self.mapView = (OAMapRendererView *)mapView;
}


-(void)setNavigationController:(UINavigationController*)controller {
    self.navController = controller;
}

#pragma mark - Actions
- (IBAction)buttonFavoriteClicked:(id)sender {
    
    
    NSString *locText;
    if (self.isAddressFound)
        locText = [self.addressLabel.text copy];
    else
        locText = self.formattedLocation;
    
    OAFavoriteItemViewController* addFavoriteVC = [[OAFavoriteItemViewController alloc] initWithLocation:CLLocationCoordinate2DMake(self.lat, self.lon)
                                                                                                andTitle:locText];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        // For iPhone and iPod, push menu to navigation controller
        [self.navController pushViewController:addFavoriteVC animated:YES];
    }
    else //if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        // For iPad, open menu in a popover with it's own navigation controller
        UINavigationController* navigationController = [[OANavigationController alloc] initWithRootViewController:addFavoriteVC];
        UIPopoverController* popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        
        [popoverController presentPopoverFromRect:CGRectMake(self.touchPoint.x, self.touchPoint.y, 0.0f, 0.0f)
                                           inView:self.mapView
                         permittedArrowDirections:UIPopoverArrowDirectionAny
                                         animated:YES];
    }
    
    [self.delegate targetPointAddFavorite];
}

- (IBAction)buttonShareClicked:(id)sender {

    UIImage *image = [self.mapView getGLScreenshot];
    NSString *string = [NSString stringWithFormat:@"Look at this location: %@", self.formattedLocation];
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[image, string]
                                      applicationActivities:nil];
    
    [self.navController presentViewController:activityViewController
                                     animated:YES
                                   completion:^{ }];

    [self.delegate targetPointShare];
}

- (IBAction)buttonDirectionClicked:(id)sender {
    [self.delegate targetPointDirection];
}



@end
