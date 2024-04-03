//
//  CoreResourcesFromBundleProvider.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 12/8/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#ifndef __OsmAnd__CoreResourcesFromBundleProvider__
#define __OsmAnd__CoreResourcesFromBundleProvider__

#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>

#include <OsmAndCore/ICoreResourcesProvider.h>

class CoreResourcesFromBundleProvider : public OsmAnd::ICoreResourcesProvider
{
private:
    static NSString* getResourcePath(const QString& name, const bool logErrors);
    static NSString* getResourcePath(const QString& name,
                                     const float displayDensityFactor,
                                     const bool logErrors);
protected:
public:
    CoreResourcesFromBundleProvider();
    virtual ~CoreResourcesFromBundleProvider();

    virtual QByteArray getResource(const QString& name,
                                   const float displayDensityFactor,
                                   bool* ok = nullptr) const;
    virtual QByteArray getResource(const QString& name,
                                   bool* ok = nullptr) const;
    
    virtual bool containsResource(const QString& name,
                                  const float displayDensityFactor) const;
    virtual bool containsResource(const QString& name) const;
};

#endif /* defined(__OsmAnd__CoreResourcesFromBundleProvider__) */
