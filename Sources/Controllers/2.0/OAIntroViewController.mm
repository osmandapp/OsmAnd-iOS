//
//  OAIntroViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 19.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAIntroViewController.h"
#import "Localization.h"
#import "OAInitViewPanel.h"
#import "OsmAndApp.h"
#import "OAResourcesBaseViewController.h"
#import "OAAutocompleteManager.h"


#import "Localization.h"


@interface OAIntroViewController ()

@end

@implementation OAIntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = YES;
    // Do any additional setup after loading the view from its nib.
}

-(void)viewDidAppear:(BOOL)animated {

    OAInitViewPanel *panel1 = [[OAInitViewPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"OAInitViewPanel"];
    panel1.nextButton.layer.cornerRadius = 5;
    [panel1.nextButton setAlpha:1];
    [panel1.descriptionView setText:@""];
    
    OAInitViewPanel *panel2 = [[OAInitViewPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"OAInitViewPanel"];
    panel2.nextButton.layer.cornerRadius = 5;
    [panel2.nextButton setAlpha:1];
    [panel2.labelView setText:@"Wherever you are"];
    [panel2.descriptionView setText:@"Maps & navigation without Internet connection!"];
    
    OAInitViewPanel *panel3 = [[OAInitViewPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"OAInitViewPanel"];
    panel3.nextButton.layer.cornerRadius = 5;
    [panel3.nextButton setAlpha:1];
    [panel3.nextButton setTitle:@"Skip" forState:UIControlStateNormal];
    CGRect frame = panel3.labelView.frame;
    frame.size.height = 240;
    [panel3.labelView setFrame:frame];
    [panel3.labelView setText:@"To continue, select your preferred region for loading maps"];
    [panel3.descriptionView setText:@""];
    [panel3.countryName setHidden:NO];
    UIImageView* searchImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    [searchImage setContentMode:UIViewContentModeCenter];
    [searchImage setImage:[UIImage imageNamed:@"search_icon"]];
    [panel3.countryName setLeftView: searchImage];
    [panel3.countryName setLeftViewMode:UITextFieldViewModeAlways];
    panel3.countryName.layer.cornerRadius = 5;
    panel3.countryName.delegate = self;
    [panel3.countryName setKeyboardType:UIKeyboardTypeAlphabet];
    
    
    NSArray *panels = @[panel1, panel2, panel3];
    //Create the introduction view and set its delegate
    MYBlurIntroductionView *introductionView = [[MYBlurIntroductionView alloc] initWithFrame:CGRectMake(0, 0, DeviceScreenWidth, DeviceScreenHeight)];
    [introductionView buildIntroductionWithPanels:panels];
    [introductionView setBackgroundColor:[UIColor orangeColor]];
    introductionView.delegate = self;
    [introductionView.RightSkipButton setTitle:@"" forState:UIControlStateNormal];
    introductionView.RightSkipButton = nil;
    
    //Add the introduction to your view
    [self.view addSubview:introductionView];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)introduction:(MYBlurIntroductionView *)introductionView didFinishWithType:(MYFinishType)finishType {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)sender{
    [sender resignFirstResponder];
    OsmAndAppInstance app = [OsmAndApp instance];
    
    
    __block OAWorldRegion* region;
    NSString* lcString = [sender.text lowercaseString];
    [[OAAutocompleteManager sharedManager].regionList enumerateObjectsUsingBlock:^(OAWorldRegion* obj, NSUInteger idx, BOOL *stop) {
        
        if ( (obj.name && [[obj.name lowercaseString] isEqualToString:lcString]) ||
            (obj.localizedName && [[obj.localizedName lowercaseString] isEqualToString:lcString]) ) {
            region = obj;
            *stop = YES;
        }
    }];
    
    if (!region) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"Sorry, can't find region named %@", sender.text) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return YES;
    }
    
    const auto regionId = QString::fromNSString(region.regionId);
    const auto downloadsIdPrefix = QString::fromNSString(region.downloadsIdPrefix);
    
    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> > resourcesInRepository = app.resourcesManager->getResourcesInRepository();
    QString resourceId;
    for (const auto& resource : resourcesInRepository)
    {
        if (!resource->id.startsWith(downloadsIdPrefix))
            continue;

        resourceId = resource->id;
        break;
    }
    
    if (resourceId.isNull() || resourceId.isEmpty()) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"Sorry, can't find region named %@", sender.text) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return YES;
    }
    
    const auto resourceInRepository = app.resourcesManager->getResourceInRepository(resourceId);
    [OAResourcesBaseViewController startBackgroundDownloadOf:resourceInRepository];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeCustomView;
    hud.detailsLabelText = OALocalizedString(@"Downloading map of %@ is started", sender.text);
    [hud hide:YES afterDelay:2.0];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [self.navigationController popViewControllerAnimated:YES];
        
    });
    
    return YES;
}


#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}



@end
