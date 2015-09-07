//
//  OAMapMarker.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

class OAMapMarker
{
    
public:
    enum OAPinIconAlignment : unsigned int
    {
        XAxisMask = 0x3,
        Left = 0u << 0,
        CenterHorizontal = 1u << 0,
        Right = 2u << 0,
        
        YAxisMask = 0xC,
        Top = 0u << 2,
        CenterVertical = 1u << 2,
        Bottom = 2u << 2,
        
        Center = CenterHorizontal | CenterVertical,
    };
    
};
