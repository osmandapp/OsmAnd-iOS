//
//  OAPublicTransportStuleSettingsHelper.h
//  OsmAnd
//
//  Created by nnngrach on 26.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//


@interface OAPublicTransportStyleSettingsHelper : NSObject

+ (OAPublicTransportStyleSettingsHelper *)sharedInstance;

- (BOOL) getVisibilityForTransportLayer;
- (void) setVisibilityForTransportLayer:(BOOL)isVisible;
- (void) toggleVisibilityForTransportLayer;

- (NSArray *) getAllTransportStyleParameters;
- (BOOL) getVisibilityForStyleParameter:(NSString*)parameterName;
- (void) setVisibility:(BOOL)isVisible forStyleParameter:(NSString*)parameterName;
- (BOOL) isAllTransportStylesHidden;

- (NSString *) getIconNameForStyle:(NSString *)styleName;

@end

