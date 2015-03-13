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

@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIView *backView1;
@property (weak, nonatomic) IBOutlet UIView *backView2;
@property (weak, nonatomic) IBOutlet UIView *backView3;

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

- (void)layoutSubviews
{
    CGFloat h = kOATargetPointViewHeightPortrait;
    BOOL landscape = NO;
    if (DeviceScreenWidth > 470.0) {
        h = kOATargetPointViewHeightLandscape;
        landscape = YES;
    }
    
    CGRect frame = self.frame;
    frame.origin.y = DeviceScreenHeight - h;
    frame.size.width = DeviceScreenWidth;
    frame.size.height = h;
    self.frame = frame;
    
    if (landscape) {
        
        if (_imageView.image) {
            _addressLabel.frame = CGRectMake(40.0, 12.0, DeviceScreenWidth - 52.0, 21.0);
            _coordinateLabel.frame = CGRectMake(40.0, 39.0, DeviceScreenWidth - 52.0, 21.0);
        } else {
            _addressLabel.frame = CGRectMake(16.0, 12.0, DeviceScreenWidth - 24.0, 21.0);
            _coordinateLabel.frame = CGRectMake(16.0, 39.0, DeviceScreenWidth - 24.0, 21.0);
        }
        
        _buttonsView.frame = CGRectMake(DeviceScreenWidth - 210.0, 0.0, 210.0, h);
        CGFloat backViewWidth = floor(_buttonsView.frame.size.width / 3.0);
        CGFloat x = 0.0;
        _backView1.frame = CGRectMake(x, 0.0, backViewWidth, _buttonsView.frame.size.height);
        x += backViewWidth + 1.0;
        _backView2.frame = CGRectMake(x, 0.0, backViewWidth, _buttonsView.frame.size.height);
        x += backViewWidth + 1.0;
        _backView3.frame = CGRectMake(x, 0.0, _buttonsView.frame.size.width - x, _buttonsView.frame.size.height);
        _buttonFavorite.frame = CGRectMake(_backView1.bounds.size.width / 2.0 - _buttonFavorite.bounds.size.width / 2.0, _backView1.bounds.size.height / 2.0 - _buttonFavorite.bounds.size.height / 2.0, _buttonFavorite.bounds.size.width, _buttonFavorite.bounds.size.height);
        _buttonShare.frame = CGRectMake(_backView2.bounds.size.width / 2.0 - _buttonShare.bounds.size.width / 2.0, _backView2.bounds.size.height / 2.0 - _buttonShare.bounds.size.height / 2.0, _buttonShare.bounds.size.width, _buttonFavorite.bounds.size.height);
        _buttonDirection.frame = CGRectMake(_backView3.bounds.size.width / 2.0 - _buttonFavorite.bounds.size.width / 2.0, _backView3.bounds.size.height / 2.0 - _buttonDirection.bounds.size.height / 2.0, _buttonDirection.bounds.size.width, _buttonDirection.bounds.size.height);
        
    } else {
        
        if (_imageView.image) {
            _addressLabel.frame = CGRectMake(40.0, 12.0, DeviceScreenWidth - 52.0, 21.0);
            _coordinateLabel.frame = CGRectMake(40.0, 39.0, DeviceScreenWidth - 52.0, 21.0);
        } else {
            _addressLabel.frame = CGRectMake(16.0, 12.0, DeviceScreenWidth - 24.0, 21.0);
            _coordinateLabel.frame = CGRectMake(16.0, 39.0, DeviceScreenWidth - 24.0, 21.0);
        }
        
        _buttonsView.frame = CGRectMake(0.0, 73.0, DeviceScreenWidth, 53.0);
        CGFloat backViewWidth = floor(_buttonsView.frame.size.width / 3.0);
        CGFloat x = 0.0;
        _backView1.frame = CGRectMake(x, 1.0, backViewWidth, _buttonsView.frame.size.height - 1.0);
        x += backViewWidth + 1.0;
        _backView2.frame = CGRectMake(x, 1.0, backViewWidth, _buttonsView.frame.size.height - 1.0);
        x += backViewWidth + 1.0;
        _backView3.frame = CGRectMake(x, 1.0, _buttonsView.frame.size.width - x, _buttonsView.frame.size.height - 1.0);
        _buttonFavorite.frame = CGRectMake(_backView1.bounds.size.width / 2.0 - _buttonFavorite.bounds.size.width / 2.0, _backView1.bounds.size.height / 2.0 - _buttonFavorite.bounds.size.height / 2.0, _buttonFavorite.bounds.size.width, _buttonFavorite.bounds.size.height);
        _buttonShare.frame = CGRectMake(_backView2.bounds.size.width / 2.0 - _buttonShare.bounds.size.width / 2.0, _backView2.bounds.size.height / 2.0 - _buttonShare.bounds.size.height / 2.0, _buttonShare.bounds.size.width, _buttonFavorite.bounds.size.height);
        _buttonDirection.frame = CGRectMake(_backView3.bounds.size.width / 2.0 - _buttonFavorite.bounds.size.width / 2.0, _backView3.bounds.size.height / 2.0 - _buttonDirection.bounds.size.height / 2.0, _buttonDirection.bounds.size.width, _buttonDirection.bounds.size.height);
    }
    
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
