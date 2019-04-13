//
//  OAOnlineOsmNote.h
//  OsmAnd
//
//  Created by Paul on 4/5/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  Extracted from: OsmAnd/src/net/osmand/plus/osmedit/OsmBugsLayer.java
//  git revision 0fbb4df13460fdec70ae3fb51eb64608e5962497

#include <OsmAndCore.h>

class OAOnlineOsmNote
{
public:
    class OAComment
    {
    private:
    protected:
    public:
        OAComment();
        virtual ~OAComment();
        QString _date;
        QString _text;
        QString _user;
    };
private:
    bool _local;
    double _latitude;
    double _longitude;
    QString _description;
    QString _typeName;
    QList<std::shared_ptr<OAComment>> _comments;
    long long _identifier;
    bool _opened;
protected:
public:
    OAOnlineOsmNote();
    virtual ~OAOnlineOsmNote();
    
    double getLatitude() const;
    void setLatitude(double latitude);
    
    double getLongitude() const;
    void setLongitude(double longitude);
    
    QString getDescription() const;
    QString getTypeName() const;
    QString getCommentDescription();
    
    QList<QString> getCommentDescriptionList() const;
    
    long long getId() const;
    void setId(long long identifier);
    
    bool isOpened() const;
    void setOpened(bool opened);
    
    bool isLocal() const;
    void setLocal(bool local);
    
    QList<std::shared_ptr<OAComment> >& comments();
    QList<std::shared_ptr<OAComment> > getComments() const;
    void acquireDescriptionAndType();
};
