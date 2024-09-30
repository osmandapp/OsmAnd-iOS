//
//  OsmAndSharedWrapper.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 04.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#ifdef emit
    #pragma push_macro("emit")
    #undef emit
    #define EMIT_WAS_DEFINED 1
#endif
#define emit emit_renamed

#import <OsmAndShared/OsmAndShared.h>

#undef emit
#ifdef EMIT_WAS_DEFINED
    #pragma pop_macro("emit")
    #undef EMIT_WAS_DEFINED
#endif
