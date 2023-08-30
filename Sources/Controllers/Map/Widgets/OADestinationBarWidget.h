//
//  OADestinationTopWidget.h
//  OsmAnd Maps
//
//  Created by Alexey K on 27.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseWidgetView.h"
#import "OADestinationCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface OADestinationBarWidget : OABaseWidgetView<OADestinatioCellProtocol>

- (void) updateCloseButton;
- (CGFloat) getHeight;

@end

NS_ASSUME_NONNULL_END
