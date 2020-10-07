//
//  OACopyProfileBottomSheetView.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 05.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACopyProfileBottomSheetView.h"
#import "OAAppSettings.h"
#import "OABottomSheetHeaderDescrButtonCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAIconTitleIconRoundCell.h"
#import "OAUtilities.h"
#import "OASettingsHelper.h"
#import "OAMapStyleSettings.h"
#import "OARouteProvider.h"
#import "OAMapWidgetRegInfo.h"
#import "OAMapWidgetRegistry.h"
#import "OARootViewController.h"

#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"

#define kCellTypeCheck @"OAIconTextCell"
#define kIconTitleIconRoundCell @"OAIconTitleIconRoundCell"
#define kOABottomSheetWidth 320.0
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)

typedef NS_ENUM(NSInteger, EOACopyProfileMenuState)
{
    EOACopyProfileMenuStateInitial = 0,
    EOACopyProfileMenuStateFullScreen
};

@interface OACopyProfileBottomSheetView()<UIGestureRecognizerDelegate>

@end

@implementation OACopyProfileBottomSheetView
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    OAApplicationMode *_targetAppMode;
    OAApplicationMode *_sourceAppMode;
    NSInteger _selectedModeIndex;
    
    UIPanGestureRecognizer *_panGesture;
    EOACopyProfileMenuState _currentState;
    CGFloat _initialTouchPoint;
    BOOL _isDragging;
    BOOL _isHiding;
}

- (instancetype) initWithMode:(OAApplicationMode *)am
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OACopyProfileBottomSheetView class]])
            self = (OACopyProfileBottomSheetView *) v;
    }
    if (self)
    {
        _targetAppMode = am;
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
    [self.layer setCornerRadius:12.];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _titleView.text = OALocalizedString(@"copy_from_other_profile");
    
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
    _panGesture.delaysTouchesBegan = NO;
    _panGesture.delaysTouchesEnded = NO;
    _panGesture.delegate = self;
    [self addGestureRecognizer:_panGesture];
    
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
    _settings = [OAAppSettings sharedManager];
    [self generateData];
}

- (void) generateData
{
    NSMutableArray *dataArr = [NSMutableArray array];
    
    for (OAApplicationMode *am in OAApplicationMode.allPossibleValues)
    {
        if ([am.stringKey isEqualToString:_targetAppMode.stringKey])
            continue;
        [dataArr addObject:@{
            @"type" : kIconTitleIconRoundCell,
            @"app_mode" : am,
            @"selected" : @(_sourceAppMode == am),
        }];
    }
    _data = [NSArray arrayWithObject:dataArr];
    
    _cpyProfileButton.userInteractionEnabled = _sourceAppMode;
    _cpyProfileButton.backgroundColor = _sourceAppMode ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_route_button_inactive);
    [_cpyProfileButton setTintColor:_sourceAppMode ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [_cpyProfileButton setTitleColor:_sourceAppMode ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont systemFontOfSize: 15.0];
    CGFloat textWidth = self.bounds.size.width - 32;
    return [OAUtilities heightForHeaderViewText:text width:textWidth font:labelFont lineSpacing:6.0];
}

- (void) layoutSubviews
{
    if (_isHiding || _isDragging)
        return;
    [super layoutSubviews];
    [self adjustFrame];
    
    [_tableView setScrollEnabled:_currentState == EOACopyProfileMenuStateFullScreen];

    CGRect contentFrame = _contentContainer.frame;
    contentFrame.size.width = self.bounds.size.width;
    contentFrame.origin.y = CGRectGetMaxY(_statusBarBackgroundView.frame);
    contentFrame.size.height -= contentFrame.origin.y;
    _contentContainer.frame = contentFrame;
    
    _headerView.frame = CGRectMake(0., _headerView.frame.origin.y, contentFrame.size.width, _headerView.frame.size.height);
    
    [self applyCornerRadius:self.headerView];
    [self applyCornerRadius:self.contentContainer];
}

- (void) adjustFrame
{
    CGRect f = self.frame;
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if (OAUtilities.isLandscape)
    {
        f.size.height = DeviceScreenHeight;
        f.size.width = OAUtilities.isIPad ? kOABottomSheetWidthIPad : kOABottomSheetWidth;
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
        f.size.height = [self getViewHeight];
        f.size.width = DeviceScreenWidth;
        f.origin = CGPointMake(0, DeviceScreenHeight - f.size.height);
        
        CGRect buttonsFrame = _buttonsView.frame;
        buttonsFrame.size.height = 60. + bottomMargin;
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
    _isHiding = NO;
    _currentState = OAUtilities.isLandscape ? EOACopyProfileMenuStateFullScreen : EOACopyProfileMenuStateInitial;
    [_tableView setScrollEnabled:_currentState == EOACopyProfileMenuStateFullScreen];
    [self generateData];
    [self setNeedsLayout];
    [self adjustFrame];
    [self.tableView reloadData];
    if (animated)
    {
        CGRect frame = self.frame;
        if (OAUtilities.isLandscape)
        {
            frame.origin.x = DeviceScreenWidth/2 - frame.size.width / 2;
            frame.size.width = OAUtilities.isIPad ? kOABottomSheetWidthIPad : kOABottomSheetWidth;
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
        if (OAUtilities.isLandscape)
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
                if (self.delegate)
                    [self.delegate onCopyProfileDismissed];
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
    [self copyProfile];
    if (self.delegate)
        [self.delegate onCopyProfileCompleted];
    [self hide:YES];
}

- (void) copyRegisteredPreferences
{
    for (NSString *key in _settings.getRegisteredSettings)
    {
        OAProfileSetting *setting = [_settings.getRegisteredSettings objectForKey:key];
        if (setting)
            [setting copyValueFromAppMode:_sourceAppMode targetAppMode:_targetAppMode];
    }
}

- (void) copyRoutingPreferences
{
    const auto router = [OARouteProvider getRouter:_sourceAppMode];
    if (router)
    {
        const auto& parameters = router->getParametersList();
        for (const auto& p : parameters)
        {
            if (p.type == RoutingParameterType::BOOLEAN)
            {
                OAProfileBoolean *boolSetting = [_settings getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:p.id.c_str()] defaultValue:p.defaultBoolean];
                [boolSetting set:[boolSetting get:_sourceAppMode] mode:_targetAppMode];
            }
            else
            {
                OAProfileString *stringSetting = [_settings getCustomRoutingProperty:[NSString stringWithUTF8String:p.id.c_str()] defaultValue:p.type == RoutingParameterType::NUMERIC ? @"0.0" : @"-"];
                [stringSetting set:[stringSetting get:_sourceAppMode] mode:_targetAppMode];
            }
        }
    }
}

- (void) copyRenderingPreferences
{
    OAMapStyleSettings *sourceStyleSettings = [self getMapStyleSettingsForMode:_sourceAppMode];
    OAMapStyleSettings *targetStyleSettings = [self getMapStyleSettingsForMode:_targetAppMode];
    
    for (OAMapStyleParameter *param in [sourceStyleSettings getAllParameters])
    {
        OAMapStyleParameter *p = [targetStyleSettings getParameter:param.name];
        if (p)
        {
            p.value = param.value;
            [targetStyleSettings save:p refreshMap:NO];
        }
    }
}

- (NSString *) getRendererByName:(NSString *)rendererName
{
    if ([rendererName isEqualToString:@"OsmAnd"])
        return @"default";
    else if ([rendererName isEqualToString:@"Touring view (contrast and details)"])
        return @"Touring-view_(more-contrast-and-details)";
    else if (![rendererName isEqualToString:@"LightRS"] && ![rendererName isEqualToString:@"UniRS"])
        return [rendererName lowerCase];
    
    return rendererName;
}

- (OAMapStyleSettings *) getMapStyleSettingsForMode:(OAApplicationMode *)am
{
    NSString *renderer = [OAAppSettings.sharedManager.renderer get:am];
    NSString *resName = [self getRendererByName:renderer];
    return [[OAMapStyleSettings alloc] initWithStyleName:resName mapPresetName:am.variantKey];
}

- (void) copyMapWidgetRegistryPreference
{
    OAMapWidgetRegistry *mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
    for (OAMapWidgetRegInfo *r in [mapWidgetRegistry getLeftWidgetSet])
    {
        [mapWidgetRegistry setVisibility:_targetAppMode m:r visible:[r visible:_sourceAppMode] collapsed:[r visibleCollapsed:_sourceAppMode]];
    }
    for (OAMapWidgetRegInfo *r in [mapWidgetRegistry getRightWidgetSet])
    {
        [mapWidgetRegistry setVisibility:_targetAppMode m:r visible:[r visible:_sourceAppMode] collapsed:[r visibleCollapsed:_sourceAppMode]];
    }
}

- (void) copyProfile
{
    OsmAndAppInstance app = [OsmAndApp instance];
    
    [self copyRegisteredPreferences];
    [self copyRoutingPreferences];
    [app.data copyAppDataFrom:_sourceAppMode toMode:_targetAppMode];
    [self copyRenderingPreferences];
    [self copyMapWidgetRegistryPreference];
    
    if ([_targetAppMode isCustomProfile])
        [_targetAppMode setParent: [_sourceAppMode isCustomProfile] ? _sourceAppMode.parent : _sourceAppMode];
    [_targetAppMode setIconName:_sourceAppMode.getIconName];
    [_targetAppMode setRoutingProfile:_sourceAppMode.getRoutingProfile];
    [_targetAppMode setRouterService:_sourceAppMode.getRouterService];
    [_targetAppMode setIconColor:_sourceAppMode.getIconColor];
    [_targetAppMode setLocationIcon:_sourceAppMode.getLocationIcon];
    [_targetAppMode setNavigationIcon:_sourceAppMode.getNavigationIcon];
    [_targetAppMode setBaseMinSpeed:_sourceAppMode.baseMinSpeed];
    [_targetAppMode setBaseMaxSpeed:_sourceAppMode.baseMaxSpeed];
    
    [OsmAndApp.instance.data.mapLayerChangeObservable notifyEvent];
}

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
            cell.backgroundColor = UIColor.clearColor;
            cell.secondaryImageView.image = [[UIImage imageNamed:@"ic_checkmark_default"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.secondaryImageView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleView.text = am.toHumanString;
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
    _sourceAppMode = item[@"app_mode"];
    [self generateData];
    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section], [NSIndexPath indexPathForRow:_selectedModeIndex inSection:indexPath.section]] withRowAnimation:(UITableViewRowAnimation)UITableViewRowAnimationFade];
    _selectedModeIndex = indexPath.row;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat labelHeight = [OAUtilities heightForHeaderViewText:[NSString stringWithFormat:@"%@%@.", OALocalizedString(@"copy_from_other_profile_descr"), _targetAppMode.toHumanString] width:tableView.bounds.size.width - 32 font:[UIFont systemFontOfSize:15] lineSpacing:6.];
    return labelHeight + 32;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *descriptionString = [NSString stringWithFormat:@"%@%@.", OALocalizedString(@"copy_from_other_profile_descr"), _targetAppMode.toHumanString];
    CGFloat textWidth = tableView.bounds.size.width - 32;
    CGFloat heightForHeader = [OAUtilities heightForHeaderViewText:descriptionString width:textWidth font:[UIFont systemFontOfSize:15] lineSpacing:6.] + 16;
    UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0., 0., tableView.bounds.size.width, heightForHeader)];
    UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(16., 8., textWidth, heightForHeader)];
    description.attributedText = [OAUtilities getStringWithBoldPart:descriptionString mainString:OALocalizedString(@"copy_from_other_profile_descr") boldString:_targetAppMode.toHumanString lineSpacing:4.];
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
    CGPoint translation = [recognizer translationInView:self];
    CGFloat cardPanStartingTopConstant = OAUtilities.getStatusBarHeight;
    
    CGFloat velocity = [recognizer velocityInView:self.superview].y;
    BOOL slidingDown = velocity > 0;
    BOOL slidingUP = velocity < 0;
    BOOL fastDownSlide = velocity > 1000.;
    CGPoint touchPoint = [recognizer locationInView:self.superview];
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            _isDragging = YES;
            cardPanStartingTopConstant = self.frame.origin.y;
            _initialTouchPoint = [recognizer locationInView:self].y;
        }
        case UIGestureRecognizerStateChanged:
        {
            if (cardPanStartingTopConstant + translation.y > 30.0)
            {
                CGFloat newY = touchPoint.y - _initialTouchPoint;
                if (_currentState == EOACopyProfileMenuStateFullScreen)
                {
                    return;
                }
                else if (self.frame.origin.y > OAUtilities.getStatusBarHeight
                    || (_initialTouchPoint < _tableView.frame.origin.y && _tableView.contentOffset.y > 0))
                {
                    [_tableView setContentOffset:CGPointZero];
                }
                else if (newY <= OAUtilities.getStatusBarHeight || _tableView.contentOffset.y > 0)
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
                
                _statusBarBackgroundView.frame = newY == 0 ? CGRectMake(0., 0., DeviceScreenWidth, OAUtilities.getStatusBarHeight) : CGRectZero;
                
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
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            _isDragging = NO;
            if (slidingDown && _currentState == EOACopyProfileMenuStateInitial)
            {
                [self hide:YES];
                break;
            }
            else if (slidingUP && _currentState != EOACopyProfileMenuStateFullScreen)
            {
                _currentState = EOACopyProfileMenuStateFullScreen;
            }
            else if (slidingDown && !fastDownSlide)
            {
                _currentState = EOACopyProfileMenuStateInitial;
            }
            else
                return;
             [UIView animateWithDuration: 0.2 animations:^{
                 [self layoutSubviews];
             } completion:nil];
        }
        default:
        {
            break;
        }
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return !OAUtilities.isLandscape;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
