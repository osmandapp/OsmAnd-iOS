//
//  OAOnlineOsmNote.mm
//  OsmAnd
//
//  Created by Paul on 4/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOnlineOsmNote.h"

OAOnlineOsmNote::~OAOnlineOsmNote()
{
}

OAOnlineOsmNote::OAOnlineOsmNote()
: _comments(QList<std::shared_ptr<OAComment > >())
{
}


double OAOnlineOsmNote::getLatitude() const
{
    return _latitude;
}
void OAOnlineOsmNote::setLatitude(double latitude)
{
    _latitude = latitude;
}

double OAOnlineOsmNote::getLongitude() const
{
    return _longitude;
}
void OAOnlineOsmNote::setLongitude(double longitude)
{
    _longitude = longitude;
}

QString OAOnlineOsmNote::getDescription() const
{
    return _description;
}
QString OAOnlineOsmNote::getTypeName() const
{
    return _typeName;
}
QString OAOnlineOsmNote::getCommentDescription()
{
    QString mutableString = QString();
    for (QString &s : getCommentDescriptionList()) {
        if (s.length() > 0)
            mutableString.append(QStringLiteral("\n"));
        mutableString.append(s);
    }
    return mutableString;
}

QList<QString> OAOnlineOsmNote::getCommentDescriptionList() const
{
    QList<QString> res = QList<QString>();
    for (int i = 0; i < _comments.size(); i++)
    {
        QString mutableString = QString();
        bool needLineFeed = false;
        const auto& comment = _comments[i];
        if (comment->_date.length() > 0)
        {
            mutableString.append(comment->_date).append(QStringLiteral(" "));
            needLineFeed = true;
        }
        if (comment->_user.length() > 0)
        {
            mutableString.append(comment->_user).append(QStringLiteral(":"));
            needLineFeed = true;
        }
        if (needLineFeed)
            mutableString.append(QStringLiteral("\n"));
        
        mutableString.append(comment->_text);
        res << mutableString;
    }
    return res;
}

long long OAOnlineOsmNote::getId() const
{
    return _identifier;
}
void OAOnlineOsmNote::setId(long long identifier)
{
    _identifier = identifier;
}

bool OAOnlineOsmNote::isOpened() const
{
    return _opened;
}
void OAOnlineOsmNote::setOpened(bool opened)
{
    _opened = opened;
}

bool OAOnlineOsmNote::isLocal() const
{
    return _local;
}
void OAOnlineOsmNote::setLocal(bool local)
{
    _local = local;
}

QList<std::shared_ptr<OAOnlineOsmNote::OAComment>>& OAOnlineOsmNote::comments()
{
    return _comments;
}

QList<std::shared_ptr<OAOnlineOsmNote::OAComment> > OAOnlineOsmNote::getComments() const
{
    return _comments;
}

void OAOnlineOsmNote::acquireDescriptionAndType()
{
    if (_comments.size() > 0)
    {
        const auto& comment = _comments[0];
        _description = comment->_text;

        QString user = comment->_user;
        _typeName = QString(comment->_date).append(QStringLiteral(" ")).append(user != nullptr ? user : QStringLiteral("anonymous"));

        if (_description != nullptr && _description.length() < 100)
            _comments.removeAll(comment);
    }
}

OAOnlineOsmNote::OAComment::OAComment()
{
}

OAOnlineOsmNote::OAComment::~OAComment()
{
}
