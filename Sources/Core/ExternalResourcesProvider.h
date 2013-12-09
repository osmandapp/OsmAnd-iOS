//
//  ExternalResourcesProvider.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 12/8/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#ifndef __OsmAnd__ExternalResourcesProvider__
#define __OsmAnd__ExternalResourcesProvider__

#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>

#include <OsmAndCore/IExternalResourcesProvider.h>

class ExternalResourcesProvider : public OsmAnd::IExternalResourcesProvider
{
private:
protected:
public:
    ExternalResourcesProvider(const bool useHD);
    virtual ~ExternalResourcesProvider();
    
    const bool useHD;
    
    virtual QByteArray getResource(const QString& name, bool* ok = nullptr) const;
    virtual bool containsResource(const QString& name) const;
};

#endif /* defined(__OsmAnd__ExternalResourcesProvider__) */
