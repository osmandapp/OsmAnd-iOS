//
//  OASelectedGpxPoint.mm
//  OsmAnd
//
//  Created by Max Kojin on 02/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OASelectedGpxPoint.h"

@implementation OASelectedGpxPoint
{
    OASGpxFile *_selectedGpxFile;
    OASWptPt *_selectedPoint;
}

    
- (OASGpxFile *) getSelectedGpxFile
{
    return _selectedGpxFile;
}

- (OASWptPt *) getSelectedPoint
{
    return _selectedPoint;
}

//TODO: implement
    

@end
