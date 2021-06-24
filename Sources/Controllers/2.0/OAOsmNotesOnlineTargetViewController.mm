//
//  OAOsmEditViewController.m
//  OsmAnd
//
//  Created by Alexey on 28/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmNotesOnlineTargetViewController.h"
#import "OAOsmNoteBottomSheetViewController.h"
#import "OATransportStopRoute.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAMapLayers.h"
#import "OAColors.h"
#import "OACollapsableLabelView.h"
#import "OAOsmNoteBottomSheetViewController.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmNotePoint.h"
#import "Reachability.h"
#import "OAOnlineOsmNoteWrapper.h"

@interface OAOsmNotesOnlineTargetViewController () <OAOsmEditingBottomSheetDelegate>

@end

@implementation OAOsmNotesOnlineTargetViewController
{
    OsmAndAppInstance _app;
    
    OAMapViewController *_mapViewController;
    OAOnlineOsmNoteWrapper *_point;
    UIImage *_icon;
    
    OAOsmEditingPlugin *_editingPlugin;
    
    BOOL _isOpen;
}


- (instancetype) initWithNote:(OAOnlineOsmNoteWrapper *)point icon:(UIImage *)icon
{
    self = [super init];
    if (self)
    {
        _icon = icon;
        _point = point;
        _app = [OsmAndApp instance];
        _editingPlugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
        _isOpen = _point.opened;
        
        self.leftControlButton = [[OATargetMenuControlButton alloc] init];
        self.leftControlButton.title = _isOpen ? OALocalizedString(@"osm_note_comment") : OALocalizedString(@"osm_note_reopen");
        if (_isOpen)
        {
            self.rightControlButton = [[OATargetMenuControlButton alloc] init];
            self.rightControlButton.title = OALocalizedString(@"shared_string_close");
        }
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self applyTopToolbarTargetTitle];
}

- (void) leftControlButtonPressed
{
    OAOsmNoteBottomSheetViewController *bottomSheet = [[OAOsmNoteBottomSheetViewController alloc]
                                                       initWithEditingPlugin:_editingPlugin
                                                       points:[NSArray arrayWithObject:[self getNote:_isOpen ? MODIFY : REOPEN]] type:_isOpen ? TYPE_MODIFY : TYPE_REOPEN];
    bottomSheet.delegate = self;
    [bottomSheet show];
}

- (void) rightControlButtonPressed
{
    OAOsmNoteBottomSheetViewController *bottomSheet = [[OAOsmNoteBottomSheetViewController alloc]
                                                       initWithEditingPlugin:_editingPlugin
                                                       points:[NSArray arrayWithObject:[self getNote:DELETE]] type:TYPE_CLOSE];
    bottomSheet.delegate = self;
    [bottomSheet show];
}

- (OAOsmNotePoint *)getNote:(EOAAction)action
{
    OAOsmNotePoint *p = [[OAOsmNotePoint alloc] init];
    [p setId:_point.identifier];
    [p setLatitude:_point.latitude];
    [p setLongitude:_point.longitude];
    [p setText:@""];
    [p setAction:action];
    return p;
}

- (NSString *) getTypeStr;
{
    return _point.typeName;
}


- (UIColor *) getAdditionalInfoColor
{
    return UIColorFromRGB(color_ctx_menu_amenity_opened_text);
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return nil;
}

- (UIImage *) getAdditionalInfoImage
{
    return nil;
}

- (id) getTargetObj
{
    return _point;
}

- (BOOL) showNearestWiki
{
    return NO;
}

- (BOOL) showNearestPoi
{
    return NO;
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    NSMutableArray<OARowInfo *> *descriptions = [NSMutableArray array];
    
    for (OACommentWrapper *cw in _point.comments)
    {
        [descriptions addObject:[[OARowInfo alloc] initWithKey:@"" icon:[OATargetInfoViewController getIcon:@"ic_description.png"] textPrefix:nil text:[NSString stringWithFormat:@"%@ %@: %@", cw.date, cw.user, cw.text] textColor:nil isText:YES needLinks:YES order:0 typeName:@"" isPhoneNumber:NO isUrl:NO]];
    }
    
    int i = 10000;
    for (OARowInfo *desc in descriptions)
    {
        desc.order = i++;
        [rows addObject:desc];
    }
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFloating;
}

#pragma mark - OAOsmEditingBottomSheetDelegate

-(void) refreshData
{
}

- (void) dismissEditingScreen
{
    [[OARootViewController instance].mapPanel targetHide];
}


@end
