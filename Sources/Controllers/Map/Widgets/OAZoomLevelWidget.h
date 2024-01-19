//
//  OAZoomLevelWidget.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"

@interface OAZoomLevelWidget : OATextInfoWidget

- (instancetype _Nonnull)initWithСustomId:(NSString *_Nullable)customId
                                  appMode:(OAApplicationMode * _Nonnull)appMode;

@end
