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
#import "OAWebViewController.h"

@interface OAOptionsPanelBlackViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMaps;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMyData;
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
            
            
        } else {
            
            CGFloat topY = 70.0;
            CGFloat buttonHeight = 50.0;
            CGFloat scrollHeight = big - topY;
            
            self.scrollView.frame = CGRectMake(0.0, topY, small, scrollHeight);
            self.scrollView.contentSize = CGSizeMake(small, scrollHeight);
            
            self.menuButtonMaps.frame = CGRectMake(-2.0, 0.0, small + 2.0, buttonHeight);
            self.menuButtonMyData.frame = CGRectMake(-2.0, buttonHeight * 1.0 - 1.0, small + 2.0, buttonHeight);
            self.menuButtonMapsAndResources.frame = CGRectMake(-2.0, buttonHeight * 2.0 - 2.0, small + 2.0, buttonHeight);

            self.menuButtonSettings.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 3.0 + 1.0, small + 2.0, buttonHeight);
            self.menuButtonQuiz.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 2.0 + 0.0, small + 2.0, buttonHeight);
            self.menuButtonHelp.frame = CGRectMake(-2.0, scrollHeight - buttonHeight, small + 2.0, buttonHeight);
        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            CGFloat topY = 70.0;
            CGFloat buttonHeight = 50.0;
            CGFloat viewWidth = self.view.bounds.size.width;
            CGFloat scrollHeight = small - topY;

            self.scrollView.frame = CGRectMake(0.0, topY, viewWidth, scrollHeight);
            
            if (6 * buttonHeight < self.scrollView.frame.size.height) {
                
                self.menuButtonMaps.frame = CGRectMake(-2.0, 0.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonMyData.frame = CGRectMake(-2.0, buttonHeight * 1.0 - 1.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonMapsAndResources.frame = CGRectMake(-2.0, buttonHeight * 2.0 - 2.0, viewWidth + 2.0, buttonHeight);
                
                self.menuButtonSettings.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 3.0 + 1.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonQuiz.frame = CGRectMake(-2.0, scrollHeight - buttonHeight * 2.0 + 0.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonHelp.frame = CGRectMake(-2.0, scrollHeight - buttonHeight, viewWidth + 2.0, buttonHeight);
                
                self.scrollView.contentSize = CGSizeMake(viewWidth, scrollHeight);

            } else {
                
                self.menuButtonMaps.frame = CGRectMake(-2.0, 0.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonMyData.frame = CGRectMake(-2.0, buttonHeight * 1.0 - 1.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonMapsAndResources.frame = CGRectMake(-2.0, buttonHeight * 2.0 - 2.0, viewWidth + 2.0, buttonHeight);
                
                self.menuButtonSettings.frame = CGRectMake(-2.0, buttonHeight * 3.0 - 3.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonQuiz.frame = CGRectMake(-2.0, buttonHeight * 4.0 - 4.0, viewWidth + 2.0, buttonHeight);
                self.menuButtonHelp.frame = CGRectMake(-2.0, buttonHeight * 5.0 - 5.0, viewWidth + 2.0, buttonHeight);

                self.scrollView.contentSize = CGSizeMake(viewWidth, buttonHeight * 5.0 - 5.0 + buttonHeight);
            }
            
        }
        
    }
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated {
    
    UIColor *borderColor = [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:71.0/255.0 alpha:1];
    
    self.menuButtonMaps.layer.borderColor = [borderColor CGColor];
    self.menuButtonMaps.layer.borderWidth = 0.5;
    
    self.menuButtonMyData.layer.borderColor = [borderColor CGColor];
    self.menuButtonMyData.layer.borderWidth = 0.5;
    
    self.menuButtonMapsAndResources.layer.borderColor = [borderColor CGColor];
    self.menuButtonMapsAndResources.layer.borderWidth = 0.5;
        
    self.menuButtonSettings.layer.borderColor = [borderColor CGColor];
    self.menuButtonSettings.layer.borderWidth = 0.5;
    
    self.menuButtonQuiz.layer.borderColor = [borderColor CGColor];
    self.menuButtonQuiz.layer.borderWidth = 0.5;
    
    self.menuButtonHelp.layer.borderColor = [borderColor CGColor];
    self.menuButtonHelp.layer.borderWidth = 0.5;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)mapsButtonClicked:(id)sender {
    OAMapSettingsViewController* settingsViewController = [[OAMapSettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (IBAction)myDataButtonClicked:(id)sender {
    OAFavoriteListViewController* settingsViewController = [[OAFavoriteListViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (IBAction)settingsButtonClicked:(id)sender {
    OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenGeneral];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}


- (IBAction)mapsAndResourcesButtonClicked:(id)sender {
    OASuperViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
    [self.navigationController pushViewController:resourcesViewController animated:YES];
}

- (IBAction)helpButtonClicked:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Copyright OsmAnd 2015" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (IBAction)quizButtonClicked:(id)sender {
    OAWebViewController* quizViewController = [[OAWebViewController alloc] initWithUrl:@"http://www.osmand.net/ios-poll.html"];
    [self.navigationController pushViewController:quizViewController animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

@end
