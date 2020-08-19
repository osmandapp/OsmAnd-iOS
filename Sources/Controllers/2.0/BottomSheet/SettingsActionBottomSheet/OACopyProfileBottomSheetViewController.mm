//
//  OACopyProfileBottomSheetViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 05.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACopyProfileBottomSheetViewController.h"
#import "OAAppSettings.h"
#import "OABottomSheetHeaderDescrButtonCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAIconTitleIconRoundCell.h"
#import "OAUtilities.h"
#import "OASettingsHelper.h"
#import "OAMapStyleSettings.h"
#import "OrderedDictionary.h"
#import "OAConfigureProfileViewController.h"

#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"

#define kCellTypeCheck @"OAIconTextCell"
#define kIconTitleIconRoundCell @"OAIconTitleIconRoundCell"
#define kButtonsDividerTag 150
#define kHeaderViewFont [UIFont systemFontOfSize:15.0]

typedef NS_ENUM(NSInteger, EOACopyProfileMenuState)
{
    EOACopyProfileMenuStateInitial = 0,
    EOACopyProfileMenuStateFullScreen
};

@interface OACopyProfileBottomSheetViewController()<UIGestureRecognizerDelegate>

@end

@implementation OACopyProfileBottomSheetViewController
{
    NSArray<NSArray *> *_data;
    NSArray<OAApplicationMode *> *_appProfiles;
    OAApplicationMode *_appMode;
    OAApplicationMode *_selectedMode;
    NSInteger _selectedModeIndex;
    UIPanGestureRecognizer *_panGesture;
    EOACopyProfileMenuState _currentState;
    CGFloat _initialTouchPoint;
    BOOL _isDragging;
    BOOL _isHiding;
    BOOL _topOverScroll;
}

- (instancetype) initWithFrame:(CGRect)frame mode:(OAApplicationMode *)am
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OACopyProfileBottomSheetViewController class]])
            self = (OACopyProfileBottomSheetViewController *) v;
    }
    if (self)
    {
        self.frame = frame;
        _appMode = am;
        [self commonInit];
    }
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowOpacity:0.3];
    [self.layer setShadowRadius:3.0];
    [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    
    _titleView.text = OALocalizedString(@"copy_profile");
    
    _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
    [_tableView setShowsVerticalScrollIndicator:YES];
    _tableView.estimatedRowHeight = kEstimatedRowHeight;
    _tableView.layer.cornerRadius = 12.;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    _sliderView.layer.cornerRadius = 2.;
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDragged:)];
    _panGesture.maximumNumberOfTouches = 1;
    _panGesture.minimumNumberOfTouches = 1;
    [self addGestureRecognizer:_panGesture];
    _panGesture.delegate = self;
    
    [_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    _cancelButton.layer.cornerRadius = 9.;
    [_cpyProfileButton setTitle:OALocalizedString(@"shared_string_copy") forState:UIControlStateNormal];
    _cpyProfileButton.layer.cornerRadius = 9.;
    [_closeButton setImage:[[UIImage imageNamed:@"ic_custom_close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _closeButton.tintColor = UIColorFromRGB(color_primary_purple);
    
    _currentState = EOACopyProfileMenuStateInitial;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *arr = [NSMutableArray array];
    
    for (OAApplicationMode *am in OAApplicationMode.allPossibleValues)
    {
        if ([am.name isEqualToString:_appMode.name])
            continue;
        [arr addObject:@{
            @"type" : kIconTitleIconRoundCell,
            @"app_mode" : am,
            @"selected" : @(_selectedMode == am),
        }];
    }
    [tableData addObject:arr];
    _data = [NSArray arrayWithArray:tableData];
    _cpyProfileButton.userInteractionEnabled = _selectedMode;
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont systemFontOfSize: 15.0];
    CGFloat textWidth = self.bounds.size.width - 32;
    return [OAUtilities heightForHeaderViewText:text width:textWidth font:labelFont lineSpacing:6.0];
}

- (BOOL) isLandscape
{
    return (OAUtilities.isLandscape || OAUtilities.isIPad) && !OAUtilities.isWindowed;
}

- (BOOL) onlyDefaultProfiles // check if needed
{
    for (OAApplicationMode *am in OAApplicationMode.allPossibleValues)
    {
        if ([am isCustomProfile])
            return NO;
    }
    return YES;
}

- (CGFloat) getViewWidthForPad
{
    return OAUtilities.isLandscape ? kInfoViewLandscapeWidthPad : kInfoViewPortraitWidthPad;
}

- (void) layoutSubviews
{
    if (_isHiding)
        return;
    [super layoutSubviews];
    [self adjustFrame];
    
    BOOL isLandscape = [self isLandscape];
    [_tableView setScrollEnabled:isLandscape];
    
    CGRect sliderFrame = _sliderView.frame;
    sliderFrame.origin.x = self.bounds.size.width / 2 - sliderFrame.size.width / 2;
    _sliderView.frame = sliderFrame;
    
    CGRect buttonsFrame = _buttonsView.frame;
    buttonsFrame.size.width = self.bounds.size.width;
    _buttonsView.frame = buttonsFrame;
    
    CGRect contentFrame = _contentContainer.frame;
    contentFrame.size.width = self.bounds.size.width;
    contentFrame.origin.y = CGRectGetMaxY(_statusBarBackgroundView.frame);
    contentFrame.size.height -= contentFrame.origin.y;
    _contentContainer.frame = contentFrame;
    
    CGFloat width = buttonsFrame.size.width - OAUtilities.getLeftMargin * (isLandscape ? 1 : 2) - 32.;
    CGFloat buttonWidth = width / 2 - 8;
    
    _cancelButton.frame = CGRectMake(16. + OAUtilities.getLeftMargin, 9., buttonWidth, 42.);
    _cpyProfileButton.frame = CGRectMake(CGRectGetMaxX(_cancelButton.frame) + 16., 9., buttonWidth, 42.);
    _sliderView.hidden = isLandscape;
    
    CGFloat tableViewY = CGRectGetMaxY(_headerView.frame);
    _tableView.frame = CGRectMake(0., tableViewY, contentFrame.size.width, contentFrame.size.height - tableViewY);
    _headerView.frame = CGRectMake(0., _headerView.frame.origin.y, contentFrame.size.width, _headerView.frame.size.height);
    
    [self applyCornerRadius:self.headerView];
    [self applyCornerRadius:self.contentContainer];
}

- (void) adjustFrame
{
    CGRect f = self.frame;
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if ([self isLandscape])
    {
        f.size.height = DeviceScreenHeight;
        f.size.width = OAUtilities.isIPad ? [self getViewWidthForPad] : DeviceScreenWidth * 0.45;
        f.origin = CGPointMake(DeviceScreenWidth/2 - f.size.width / 2, 0.);
        
        CGRect buttonsFrame = _buttonsView.frame;
        buttonsFrame.origin.y = f.size.height - 60. - bottomMargin;
        buttonsFrame.size.height = 60. + bottomMargin;
        _buttonsView.frame = buttonsFrame;
        
        CGRect contentFrame = _contentContainer.frame;
        contentFrame.size.height = f.size.height - buttonsFrame.size.height;
        contentFrame.origin = CGPointZero;
        _contentContainer.frame = contentFrame;
    }
    else
    {
        CGRect buttonsFrame = _buttonsView.frame;
        buttonsFrame.size.height = 60. + bottomMargin;
        f.size.height = [self getViewHeight];
        f.size.width = DeviceScreenWidth;
        f.origin = CGPointMake(0, DeviceScreenHeight - f.size.height);
        
        buttonsFrame.origin.y = f.size.height - buttonsFrame.size.height;
        _buttonsView.frame = buttonsFrame;
        
        CGRect contentFrame = _contentContainer.frame;
        contentFrame.size.height = f.size.height - buttonsFrame.size.height;
        contentFrame.origin = CGPointZero;
        _contentContainer.frame = contentFrame;
    }
    self.frame = f;
}

- (void) applyCornerRadius:(UIView *)view
{
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect: view.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: CGSizeMake(12., 12.)].CGPath;

    view.layer.mask = maskLayer;
}

- (CGFloat) getViewHeight
{
    switch (_currentState) {
        case EOACopyProfileMenuStateInitial:
            return DeviceScreenHeight - DeviceScreenHeight / 4;
        case EOACopyProfileMenuStateFullScreen:
            return DeviceScreenHeight - OAUtilities.getTopMargin;
        default:
            return 0.0;
    }
}

- (void) show:(BOOL)animated
{
    [_tableView setContentOffset:CGPointZero];
    BOOL isLandscape = [self isLandscape];
    _isHiding = NO;
    _currentState = isLandscape ? EOACopyProfileMenuStateFullScreen : EOACopyProfileMenuStateInitial;
    [_tableView setScrollEnabled:_currentState == EOACopyProfileMenuStateFullScreen];
    [self generateData];
    [self setNeedsLayout];
    [self adjustFrame];
    [self.tableView reloadData];
    if (animated)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
        {
            frame.origin.x = DeviceScreenWidth/2 - frame.size.width / 2;
            frame.size.width = OAUtilities.isIPad ? [self getViewWidthForPad] : DeviceScreenWidth * 0.45;
        }
        else
        {
            frame.origin.x = 0.0;
            frame.size.width = DeviceScreenWidth;
        }
        frame.origin.y = DeviceScreenHeight + 10;
        self.frame = frame;
        frame.origin.y = DeviceScreenHeight - self.bounds.size.height;
        [UIView animateWithDuration:.3 animations:^{
            self.frame = frame;
        }];
    }
    else
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
            frame.origin.y = 0.0;
        else
            frame.origin.y = DeviceScreenHeight - self.bounds.size.height;
        self.frame = frame;
    }
}

- (void) hide:(BOOL)animated
{
    _isHiding = YES;
    
    if (self.superview)
    {
        CGRect frame = self.frame;
        frame.origin.y = DeviceScreenHeight + 10.0;
        
        if (animated)
        {
            [UIView animateWithDuration:0.3 animations:^{
                self.frame = frame;
            } completion:^(BOOL finished) {
                [self removeFromSuperview];
            }];
        }
        else
        {
            self.frame = frame;
            [self removeFromSuperview];
        }
    }
}

# pragma mark - Buttons Actions

- (IBAction) closeButtonPressed:(id)sender
{
    [self hide:YES];
}

- (IBAction) cancelButtonPressed:(id)sender
{
    [self hide:YES];
}

- (IBAction) copyProfileButtonPressed:(id)sender
{
    NSLog(@"Copy");
    [self copyProfile];
}

- (void) copyProfile
{
//    OASettingsHelper *settingsHelper = [OASettingsHelper sharedInstance];
//    settingsHelper.
 
    
    MutableOrderedDictionary *res = [MutableOrderedDictionary new];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    
    for (NSString *key in settings.getRegisteredSettings)
    {
        NSLog(@"getRegisteredSettings -> %@", key);
        OAProfileSetting *setting = [settings.getRegisteredSettings objectForKey:key];
        NSLog(@"type -> %@", setting.key);
        //[setting set]
        
        //[setting setValueFromString:<#(NSString *)#> appMode:<#(OAApplicationMode *)#>];
        
        if (setting)
            res[key] = [setting toStringValue:_appMode];
    }
    [OsmAndApp.instance.data addPreferenceValuesToDictionary:res mode:_appMode];
    OAMapStyleSettings *styleSettings = [OAMapStyleSettings sharedInstance];
    NSString *renderer = nil;
    for (OAMapStyleParameter *param in [styleSettings getAllParameters])
    {
        if (!renderer)
            renderer = param.mapStyleName;
        NSLog(@"param ->%@", param);
       // res[[@"nrenderer_" stringByAppendingString:param.name]] = param.value;
    }
    if (renderer)
    {
        NSLog(@"renderer ->%@", renderer);
        //res[@"renderer"] = [self getRendererStringValue:renderer];
    }
}
    /*
//    OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:_selectedMode.stringKey
//                                                             def:[[OAApplicationMode alloc] initWithName:_selectedMode.name stringKey:_selectedMode.stringKey]];
//    [mode setParent:_selectedMode.parent];
//    [mode setIconName:_selectedMode.iconName];
//    [mode setUserProfileName:[_selectedMode.name trim]];
//    [mode setRoutingProfile:_selectedMode.routingProfile];
//    [mode setRouterService:_selectedMode.routeService];
//    [mode setIconColor:_selectedMode.color];
//    [mode setLocationIcon:_selectedMode.locationIcon];
//    [mode setNavigationIcon:_selectedMode.navigationIcon];
}
*/

#pragma mark - Table View

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    if ([item[@"type"] isEqualToString:kIconTitleIconRoundCell])
    {
        static NSString* const identifierCell = kIconTitleIconRoundCell;
        OAIconTitleIconRoundCell* cell = nil;
        OAApplicationMode *am = item[@"app_mode"];
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kIconTitleIconRoundCell owner:self options:nil];
            cell = (OAIconTitleIconRoundCell *)[nib objectAtIndex:0];
            cell.secondaryImageView.image = [[UIImage imageNamed:@"ic_checkmark_default"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.secondaryImageView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            cell.titleView.text = am.name;
            UIImage *img = am.getIcon;
            cell.iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(am.getIconColor);
            cell.secondaryImageView.hidden = ![item[@"selected"] boolValue];
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == OAApplicationMode.allPossibleValues.count - 2)];
            cell.separatorView.hidden = indexPath.row == OAApplicationMode.allPossibleValues.count - 2;
        }
        return cell;
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    _selectedMode = item[@"app_mode"];
    [self generateData];
    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section], [NSIndexPath indexPathForRow:_selectedModeIndex inSection:indexPath.section]] withRowAnimation:(UITableViewRowAnimation)UITableViewRowAnimationFade];
    _selectedModeIndex = indexPath.row;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat labelHeight = [OAUtilities heightForHeaderViewText:[NSString stringWithFormat:@"%@%@.", OALocalizedString(@"copy_profile_descr"), _appMode.name] width:tableView.bounds.size.width - 32 font:[UIFont systemFontOfSize:15] lineSpacing:6.];
    return labelHeight + 32;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *descriptionString = [NSString stringWithFormat:@"%@%@.", OALocalizedString(@"copy_profile_descr"), _appMode.name];
    CGFloat textWidth = tableView.bounds.size.width - 32;
    CGFloat heightForHeader = [OAUtilities heightForHeaderViewText:descriptionString width:textWidth font:[UIFont systemFontOfSize:15] lineSpacing:6.] + 16;
    UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0., 0., tableView.bounds.size.width, heightForHeader)];
    UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(16., 8., textWidth, heightForHeader)];
    description.attributedText = [OAUtilities getStringWithBoldPart:descriptionString mainString:OALocalizedString(@"copy_profile_descr") boldString:_appMode.name lineSpacing:4.];
    description.textColor = UIColorFromRGB(color_text_footer);
    description.numberOfLines = 0;
    description.lineBreakMode = NSLineBreakByWordWrapping;
    description.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [vw addSubview:description];
    return vw;
}

#pragma mark - UIPanGestureRecognizer

- (CGPoint) calculateInitialPoint
{
    return CGPointMake(0., DeviceScreenHeight - [self getViewHeight]);
}

- (void) onDragged:(UIPanGestureRecognizer *)recognizer
{
    CGFloat velocity = [recognizer velocityInView:self.superview].y;
    BOOL slidingDown = velocity > 0;
    BOOL fastUpSlide = velocity < -1500.;
    BOOL fastDownSlide = velocity > 1500.;
    CGPoint touchPoint = [recognizer locationInView:self.superview];
    CGPoint initialPoint = [self calculateInitialPoint];

    CGFloat fullScreenAnchor = OAUtilities.getStatusBarHeight + 40.;
    CGFloat expandedAnchor = DeviceScreenHeight / 4 + 40.;

    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            _isDragging = YES;
            _initialTouchPoint = [recognizer locationInView:self].y;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat newY = touchPoint.y - _initialTouchPoint;
            if (self.frame.origin.y > OAUtilities.getStatusBarHeight
                || (_initialTouchPoint < _tableView.frame.origin.y && _tableView.contentOffset.y > 0))
            {
                [_tableView setContentOffset:CGPointZero];
            }

            if (newY <= OAUtilities.getStatusBarHeight || _tableView.contentOffset.y > 0)
            {
                newY = 0;
                if (_tableView.contentOffset.y > 0)
                    _initialTouchPoint = [recognizer locationInView:self].y;
            }
            else if (DeviceScreenHeight - newY < _buttonsView.frame.size.height)
            {
                return;
            }

            CGRect frame = self.frame;
            frame.origin.y = newY > 0 && newY <= OAUtilities.getStatusBarHeight ? OAUtilities.getStatusBarHeight : newY;
            frame.size.height = DeviceScreenHeight - newY;
            self.frame = frame;

            CGRect buttonsFrame = _buttonsView.frame;
            buttonsFrame.origin.y = frame.size.height - buttonsFrame.size.height;
            _buttonsView.frame = buttonsFrame;

            CGRect contentFrame = _contentContainer.frame;
            contentFrame.size.width = self.bounds.size.width;
            contentFrame.origin.y = CGRectGetMaxY(_statusBarBackgroundView.frame);
            contentFrame.size.height = frame.size.height - buttonsFrame.size.height - contentFrame.origin.y;
            _contentContainer.frame = contentFrame;

            CGFloat tableViewY = CGRectGetMaxY(_headerView.frame);
            _tableView.frame = CGRectMake(0., tableViewY, contentFrame.size.width, contentFrame.size.height - tableViewY);

            return;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            _isDragging = NO;
            BOOL shouldRefresh = NO;
            CGFloat newY = touchPoint.y - _initialTouchPoint;
            if ((newY - initialPoint.y > 180 || fastDownSlide) && _currentState == EOACopyProfileMenuStateInitial)
            {
                [self hide:YES];//[[OARootViewController instance].mapPanel closeRouteInfo];
                break;
            }
            else if (newY > DeviceScreenHeight - (170.0 + _buttonsView.frame.size.height + _tableView.frame.origin.y) && !fastUpSlide)
            {
                shouldRefresh = YES;
                _currentState = EOACopyProfileMenuStateInitial;
            }
            else if (newY < fullScreenAnchor || (!slidingDown && _currentState == EOACopyProfileMenuStateInitial) || fastUpSlide)
            {
                _currentState = EOACopyProfileMenuStateFullScreen;
                [_tableView setScrollEnabled:YES];
            }
            else if ((newY < expandedAnchor || (newY > expandedAnchor && !slidingDown)) && !fastDownSlide)
            {
                shouldRefresh = YES;
                _currentState = EOACopyProfileMenuStateInitial;
            }
            else
            {
                shouldRefresh = YES;
                _currentState = EOACopyProfileMenuStateInitial;
            }
            [UIView animateWithDuration: 0.2 animations:^{
                [self layoutSubviews];
            } completion:^(BOOL finished) {
            }];
        }
        default:
        {
            break;
        }
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ![self isLandscape];
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

//- (void) scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    if (scrollView.contentOffset.y <= 0 || self.frame.origin.y != 0)
//        [scrollView setContentOffset:CGPointZero animated:NO];
//
//    //[self setupModeViewShadowVisibility];
//}

- (void) setupModeViewShadowVisibility
{
    BOOL shouldShow = _tableView.contentOffset.y > 0 && self.frame.origin.y == 0;
    _headerView.layer.shadowOpacity = shouldShow ? 0.15 : 0.0;
}

@end
