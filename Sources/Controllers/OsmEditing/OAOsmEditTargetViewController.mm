//
//  OAOsmEditViewController.m
//  OsmAnd
//
//  Created by Alexey on 28/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmEditTargetViewController.h"
#import "OATransportStopRoute.h"
#import "OsmAndApp.h"
#import "OAMapRendererView.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAMapLayers.h"
#import "OAOsmPoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAEntity.h"
#import "OAColors.h"
#import "OAPOIHelper.h"
#import "OACollapsableLabelView.h"
#import "OAPOILocationType.h"
#import "OAPOIMyLocationType.h"
#import "OAEditPOIData.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmEditingBottomSheetViewController.h"
#import "OAOsmNoteBottomSheetViewController.h"
#import "OAOsmEditingPlugin.h"
#import "OAEditPOIData.h"
#import "Reachability.h"

@interface OAOsmEditTargetViewController () <OAOsmEditingBottomSheetDelegate>

@end

@implementation OAOsmEditTargetViewController
{
    OsmAndAppInstance _app;
    
    OAMapViewController *_mapViewController;
    OAOsmPoint *_osmPoint;
    UIImage *_icon;
    
    OAPOIHelper *_poiHelper;
    
    OAOsmEditingPlugin *_editingPlugin;
}


- (instancetype) initWithOsmPoint:(OAOsmPoint *)point icon:(UIImage *)icon
{
    self = [super init];
    if (self)
    {
        _icon = icon;
        _osmPoint =  point;
        _poiHelper = [OAPOIHelper sharedInstance];
        _app = [OsmAndApp instance];
        _editingPlugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
        
        self.leftControlButton = [[OATargetMenuControlButton alloc] init];
        self.leftControlButton.title = OALocalizedString(@"shared_string_delete");
        self.rightControlButton = [[OATargetMenuControlButton alloc] init];
        self.rightControlButton.title = OALocalizedString(@"shared_string_upload");
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
    if (_osmPoint.getGroup == BUG)
        [[OAOsmBugsDBHelper sharedDatabase] deleteAllBugModifications:(OAOsmNotePoint *)_osmPoint];
    else if (_osmPoint.getGroup == POI)
        [[OAOsmEditsDBHelper sharedDatabase] deletePOI:(OAOpenStreetMapPoint *)_osmPoint];
    [_app.osmEditsChangeObservable notifyEvent];
    [[OARootViewController instance].mapPanel targetHide];
}

- (void) rightControlButtonPressed
{
    if (_osmPoint.getGroup == POI)
    {
        OAOsmEditingBottomSheetViewController *dialog = [[OAOsmEditingBottomSheetViewController alloc]
                                                         initWithEditingUtils:_editingPlugin.getPoiModificationRemoteUtil
                                                         points:[NSArray arrayWithObject:_osmPoint]];
        dialog.delegate = self;
        [dialog show];
    }
    else if (_osmPoint.getGroup == BUG)
    {
        OAOsmNoteBottomSheetViewController *dialog = [[OAOsmNoteBottomSheetViewController alloc] initWithEditingPlugin:_editingPlugin
                                                                                                                points:[NSArray arrayWithObject:_osmPoint]
                                                                                                                  type:TYPE_UPLOAD];
        dialog.delegate = self;
        [dialog show];
    }
}

- (NSString *) getTypeStr;
{
    NSString *typeStr = [NSString stringWithFormat:@"%@ • %@", _osmPoint.getLocalizedAction, [OAOsmEditingPlugin getCategory:_osmPoint]];
    return [typeStr isEqualToString:[self.delegate getTargetTitle]] ? @"" : typeStr;
}

- (UIColor *) getAdditionalInfoColor
{
    return UIColorFromRGB(color_ctx_menu_amenity_opened_text);
}

- (NSAttributedString *) getAdditionalInfoStr
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
    UIColor *colorOpen = UIColorFromRGB(color_ctx_menu_amenity_opened_text);
    UIColor *colorClosed = UIColorFromRGB(color_ctx_menu_amenity_closed_text);
    if (_osmPoint.getGroup == BUG)
    {
        [str appendAttributedString:[[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_note_created")]];
    }
    else if (_osmPoint.getGroup == POI)
    {
        [str appendAttributedString:[[NSAttributedString alloc] initWithString:_osmPoint.getAction == MODIFY ? OALocalizedString(@"osm_target_modified") : _osmPoint.getAction == DELETE ? OALocalizedString(@"osm_target_deleted") : OALocalizedString(@"osm_target_created")]];
    }
    
    [str addAttribute:NSForegroundColorAttributeName value:_osmPoint.getAction == DELETE ? colorClosed : colorOpen range:NSMakeRange(0, str.length)];
    
    UIFont *font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    [str addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, str.length)];
    
    return str;
   
}

- (UIImage *) getAdditionalInfoImage
{
    return nil;
}

- (id) getTargetObj
{
    return _osmPoint;
}

- (BOOL) showNearestWiki
{
    return NO;
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    NSString *prefLang = [OAUtilities preferredLang];
    
    NSMutableArray<OARowInfo *> *descriptions = [NSMutableArray array];
    OAPOIType *type = [[OAPOIHelper sharedInstance] getPoiTypeByName:[_osmPoint.getSubType lowerCase]];
    if (type
        && ![type isKindOfClass:[OAPOILocationType class]]
        && ![type isKindOfClass:[OAPOIMyLocationType class]])
    {
        UIImage *icon = [type icon];
        [rows addObject:[[OARowInfo alloc] initWithKey:type.name icon:icon textPrefix:nil text:[_osmPoint getSubType] textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO]];
    }
    
    [_osmPoint.getTags enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
        BOOL skip = NO;
        NSString *textPrefix = nil;
        int poiTypeOrder = 0;
        NSString *poiTypeKeyName = @"";
        
        if ([key isEqualToString:POI_TYPE_TAG] || [key hasPrefix:REMOVE_TAG_PREFIX])
            skip = YES;
        
        OAPOIBaseType *pt = [_poiHelper getAnyPoiAdditionalTypeByKey:key];
        if (!pt && value && value.length > 0 && value.length < 50)
            pt = [_poiHelper getAnyPoiAdditionalTypeByKey:[NSString stringWithFormat:@"%@_%@", key, value]];
        
        OAPOIType *pType = nil;
        if (pt)
        {
            pType = (OAPOIType *) pt;
            poiTypeOrder = pType.order;
            poiTypeKeyName = pType.name;
        }
        
        if ([key hasPrefix:@"wiki_lang"])
        {
            skip = YES;
        }
        
        if (!skip)
        {
            [descriptions addObject:[[OARowInfo alloc] initWithKey:@"" icon:[OATargetInfoViewController getIcon:@"ic_description.png"] textPrefix:textPrefix text:[NSString stringWithFormat:@"%@=%@", key, value] textColor:nil isText:YES needLinks:YES order:0 typeName:@"" isPhoneNumber:NO isUrl:NO]];
            
        }
    }];
    
    NSString *langSuffix = [NSString stringWithFormat:@":%@", prefLang];
    OARowInfo *descInPrefLang = nil;
    for (OARowInfo *desc in descriptions)
    {
        if (desc.key.length > langSuffix.length
            && [[desc.key substringFromIndex:desc.key.length - langSuffix.length] isEqualToString:langSuffix])
        {
            descInPrefLang = desc;
            break;
        }
    }
    
    [descriptions sortUsingComparator:^NSComparisonResult(OARowInfo *row1, OARowInfo *row2) {
        if (row1.order < row2.order)
        {
            return NSOrderedAscending;
        }
        else if (row1.order == row2.order)
        {
            return [row1.typeName localizedCompare:row2.typeName];
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
    
    if (descInPrefLang)
    {
        [descriptions removeObject:descInPrefLang];
        [descriptions insertObject:descInPrefLang atIndex:0];
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

- (void)refreshData
{
}

- (void) dismissEditingScreen
{
    [[OARootViewController instance].mapPanel targetHide];
}


@end
