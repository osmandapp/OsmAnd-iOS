//
//  OATargetPointView.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 03.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATargetPointView.h"
#import "OsmAndApp.h"

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
@property UIView* mapView;
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
    
    // Buttons border
    _buttonFavorite.layer.borderWidth = 1;
    _buttonFavorite.layer.borderColor = [[UIColor colorWithWhite:0.1 alpha:0.3] CGColor];

    _buttonShare.layer.borderWidth = 1;
    _buttonShare.layer.borderColor = [[UIColor colorWithWhite:0.1 alpha:0.3] CGColor];

    _buttonDirection.layer.borderWidth = 1;
    _buttonDirection.layer.borderColor = [[UIColor colorWithWhite:0.1 alpha:0.3] CGColor];

}

-(void)setAddress:(NSString*)address {
    [self.addressLabel setText:address];
}

-(void)setPointLat:(double)lat Lon:(double)lon andTouchPoint:(CGPoint)touchPoint {
    self.lat = lat;
    self.lon = lon;
    self.touchPoint = touchPoint;
    self.formattedLocation = [[[OsmAndApp instance] locationFormatter] stringFromCoordinate:CLLocationCoordinate2DMake(lat, lon)];
    [self.coordinateLabel setText:self.formattedLocation];
}

-(void)setMapViewInstance:(UIView*)mapView {
    self.mapView = mapView;
}


-(void)setNavigationController:(UINavigationController*)controller {
    self.navController = controller;
}


#pragma mark - Actions
- (IBAction)buttonFavoriteClicked:(id)sender {
    
    OAAddFavoriteViewController* addFavoriteVC = [[OAAddFavoriteViewController alloc] initWithLocation:CLLocationCoordinate2DMake(self.lat, self.lon)
                                                                                              andTitle:self.formattedLocation];
    
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
    [self.delegate targetPointShare];
}

- (IBAction)buttonDirectionClicked:(id)sender {
    [self.delegate targetPointDirection];
}



@end
