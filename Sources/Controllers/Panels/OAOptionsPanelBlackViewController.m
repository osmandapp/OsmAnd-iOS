//
//  OAOptionsPanelBlackViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 04.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAOptionsPanelBlackViewController.h"
#import "OAMapSettingsViewController.h"
#import "OASettingsViewController.h"
#import "OAFavoriteListViewController.h"
#import "OAGPXListViewController.h"
#import "OAWebViewController.h"
#import "Localization.h"

#import <JASidePanelController.h>
#import <UIViewController+JASidePanel.h>

#import "OARootViewController.h"

@interface OAOptionsPanelBlackViewController () <UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMaps;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMyData;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMyTrips;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonSettings;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMapsAndResources;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonQuiz;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonHelp;

@end

@implementation OAOptionsPanelBlackViewController

- (void)viewWillLayoutSubviews
{
    [self updateLayout:self.interfaceOrientation];
}

- (void)updateLayout:(UIInterfaceOrientation)interfaceOrientation
{
    
    CGFloat big;
    CGFloat small;
    
    CGRect rect = self.view.bounds;
    if (rect.size.width > rect.size.height) {
        big = rect.size.width;
        small = rect.size.height;
    } else {
        big = rect.size.height;
        small = rect.size.width;
    }
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            CGFloat topY = 70.0;
            CGFloat buttonHeight = 50.0;
            CGFloat scrollHeight = big - topY;
            
            self.scrollView.frame = CGRectMake(0.0, topY, small, scrollHeight);
            self.scrollView.contentSize = CGSizeMake(small, scrollHeight);
            
            self.menuButtonMaps.frame = CGRectMake(-2.0, 0.0, small + 2.0, buttonHeight);
            self.menuButtonMyData.frame = CGRectMake(-2.0, buttonHeight * 1.0 - 1.0, small + 2.0, buttonHeight);
            self.menuButtonMyTrips.frame = CGRectMake(-2.0, buttonHeight * 2.0 - 2.0, small + 2.0, buttonHeight);
            self.menuButtonMapsAndResources.frame = CGRectMake(-2.0, buttonHeight * 3.0 - 3.0, small + 2.0, buttonHeight);
            
            self.menuButtonSettings.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 3.0 + 1.0, small + 2.0, buttonHeight);
            self.menuButtonQuiz.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 2.0 + 0.0, small + 2.0, buttonHeight);
            self.menuButtonHelp.frame = CGRectMake(-2.0, scrollHeight - buttonHeight, small + 2.0, buttonHeight);
            
        } else {
            
            CGFloat topY = 70.0;
            CGFloat buttonHeight = 50.0;
            CGFloat scrollHeight = big - topY;
            
            self.scrollView.frame = CGRectMake(0.0, topY, small, scrollHeight);
            self.scrollView.contentSize = CGSizeMake(small, scrollHeight);
            
            self.menuButtonMaps.frame = CGRectMake(-2.0, 0.0, small + 2.0, buttonHeight);
            self.menuButtonMyData.frame = CGRectMake(-2.0, buttonHeight * 1.0 - 1.0, small + 2.0, buttonHeight);
            self.menuButtonMyTrips.frame = CGRectMake(-2.0, buttonHeight * 2.0 - 2.0, small + 2.0, buttonHeight);
            self.menuButtonMapsAndResources.frame = CGRectMake(-2.0, buttonHeight * 3.0 - 3.0, small + 2.0, buttonHeight);

            self.menuButtonSettings.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 3.0 + 1.0, small + 2.0, buttonHeight);
            self.menuButtonQuiz.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 2.0 + 0.0, small + 2.0, buttonHeight);
            self.menuButtonHelp.frame = CGRectMake(-2.0, scrollHeight - buttonHeight, small + 2.0, buttonHeight);
        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            CGFloat topY = 70.0;
            CGFloat buttonHeight = 50.0;
            CGFloat scrollHeight = small - topY;
            
            self.scrollView.frame = CGRectMake(0.0, topY, big, scrollHeight);
            self.scrollView.contentSize = CGSizeMake(big, scrollHeight);
            
            self.menuButtonMaps.frame = CGRectMake(-2.0, 0.0, big + 2.0, buttonHeight);
            self.menuButtonMyData.frame = CGRectMake(-2.0, buttonHeight * 1.0 - 1.0, big + 2.0, buttonHeight);
            self.menuButtonMyTrips.frame = CGRectMake(-2.0, buttonHeight * 2.0 - 2.0, big + 2.0, buttonHeight);
            self.menuButtonMapsAndResources.frame = CGRectMake(-2.0, buttonHeight * 3.0 - 3.0, big + 2.0, buttonHeight);
            
            self.menuButtonSettings.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 3.0 + 1.0, big + 2.0, buttonHeight);
            self.menuButtonQuiz.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 2.0 + 0.0, big + 2.0, buttonHeight);
            self.menuButtonHelp.frame = CGRectMake(-2.0, scrollHeight - buttonHeight, big + 2.0, buttonHeight);
            
        } else {
            
            CGFloat topY = 70.0;
            CGFloat buttonHeight = 50.0;
            CGFloat viewWidth = self.view.bounds.size.width;
            CGFloat scrollHeight = small - topY;

            self.scrollView.frame = CGRectMake(0.0, topY, viewWidth, scrollHeight);
            
            if (7 * buttonHeight < self.scrollView.frame.size.height) {
                
                self.menuButtonMaps.frame = CGRectMake(-2.0, 0.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonMyData.frame = CGRectMake(-2.0, buttonHeight * 1.0 - 1.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonMyTrips.frame = CGRectMake(-2.0, buttonHeight * 2.0 - 2.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonMapsAndResources.frame = CGRectMake(-2.0, buttonHeight * 3.0 - 3.0, viewWidth + 2.0, buttonHeight);
                
                self.menuButtonSettings.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 3.0 + 1.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonQuiz.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 2.0 + 0.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonHelp.frame = CGRectMake(-2.0, scrollHeight - buttonHeight, viewWidth + 2.0, buttonHeight);
                
                self.scrollView.contentSize = CGSizeMake(viewWidth, scrollHeight);

            } else {
                
                self.menuButtonMaps.frame = CGRectMake(-2.0, 0.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonMyData.frame = CGRectMake(-2.0, buttonHeight * 1.0 - 1.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonMyTrips.frame = CGRectMake(-2.0, buttonHeight * 2.0 - 2.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonMapsAndResources.frame = CGRectMake(-2.0, buttonHeight * 3.0 - 3.0, viewWidth + 2.0, buttonHeight);
                
                self.menuButtonSettings.frame = CGRectMake(-2.0, buttonHeight * 4.0 - 4.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonQuiz.frame = CGRectMake(-2.0, buttonHeight * 5.0 - 5.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonHelp.frame = CGRectMake(-2.0, buttonHeight * 6.0 - 6.0, viewWidth + 2.0, buttonHeight);

                self.scrollView.contentSize = CGSizeMake(viewWidth, buttonHeight * 6.0 - 6.0 + buttonHeight);
            }
            
        }
        
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.delegate = self;
    
    [_menuButtonMaps setTitle:OALocalizedString(@"map_settings_map") forState:UIControlStateNormal];
    [_menuButtonMyData setTitle:OALocalizedString(@"my_favorites") forState:UIControlStateNormal];
    [_menuButtonMyTrips setTitle:OALocalizedString(@"menu_my_trips") forState:UIControlStateNormal];
    [_menuButtonMapsAndResources setTitle:OALocalizedString(@"res_mapsres") forState:UIControlStateNormal];
    [_menuButtonSettings setTitle:OALocalizedString(@"sett_settings") forState:UIControlStateNormal];
    [_menuButtonQuiz setTitle:OALocalizedString(@"menu_feedback") forState:UIControlStateNormal];
    [_menuButtonHelp setTitle:OALocalizedString(@"menu_about") forState:UIControlStateNormal];
}

-(void)viewWillAppear:(BOOL)animated
{
    
    UIColor *borderColor = [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:71.0/255.0 alpha:1];
    
    self.menuButtonMaps.layer.borderColor = [borderColor CGColor];
    self.menuButtonMaps.layer.borderWidth = 0.5;
    
    self.menuButtonMyData.layer.borderColor = [borderColor CGColor];
    self.menuButtonMyData.layer.borderWidth = 0.5;

    self.menuButtonMyTrips.layer.borderColor = [borderColor CGColor];
    self.menuButtonMyTrips.layer.borderWidth = 0.5;

    self.menuButtonMapsAndResources.layer.borderColor = [borderColor CGColor];
    self.menuButtonMapsAndResources.layer.borderWidth = 0.5;
        
    self.menuButtonSettings.layer.borderColor = [borderColor CGColor];
    self.menuButtonSettings.layer.borderWidth = 0.5;
    
    self.menuButtonQuiz.layer.borderColor = [borderColor CGColor];
    self.menuButtonQuiz.layer.borderWidth = 0.5;
    
    self.menuButtonHelp.layer.borderColor = [borderColor CGColor];
    self.menuButtonHelp.layer.borderWidth = 0.5;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)mapsButtonClicked:(id)sender
{
    [self.sidePanelController toggleLeftPanel:self];
    [[OARootViewController instance].mapPanel mapSettingsButtonClick:sender];
}

- (IBAction)myDataButtonClicked:(id)sender
{
    OAFavoriteListViewController* settingsViewController = [[OAFavoriteListViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (IBAction)myTripsButtonClicked:(id)sender
{
    if ([[OARootViewController instance].mapPanel hasGpxActiveTargetType])
    {
        [self.sidePanelController toggleLeftPanel:self];
    }
    else
    {
        OAGPXListViewController* gpxViewController = [[OAGPXListViewController alloc] init];
        [self.navigationController pushViewController:gpxViewController animated:YES];
    }
}

- (IBAction)settingsButtonClicked:(id)sender
{
    OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenGeneral];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (IBAction)mapsAndResourcesButtonClicked:(id)sender
{
    OASuperViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
    [self.navigationController pushViewController:resourcesViewController animated:YES];
}

- (IBAction)helpButtonClicked:(id)sender
{
    // Data is powered by OpenStreetMap ODbL, &#169; http://www.openstreetmap.org/copyright
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Copyright OsmAnd 2015\n\nData is powered by OpenStreetMap ODbL, ©\nhttp://www.openstreetmap.org/copyright" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (IBAction)quizButtonClicked:(id)sender
{
    OAWebViewController* quizViewController = [[OAWebViewController alloc] initWithUrl:@"http://www.osmand.net/ios-poll.html"];
    [self.navigationController pushViewController:quizViewController animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[OARootViewController instance] closeMenuAndPanelsAnimated:NO];
}

@end
