//
//  OAXmlStreamWriter.m
//  OsmAnd Maps
//
//  Created by Alexey K on 14.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAXmlStreamWriter.h"
#include <QFile>
#include <QBuffer>
#include <QString>
#include <QIODevice>
#include <QStack>
#include <QXmlStreamWriter>

NSString * const OAXmlStreamWriterErrorDomain = @"OAXmlStreamWriterError";

@implementation OAXmlStreamWriter
{
    QXmlStreamWriter _writer;
    
    QFile _file;
    QBuffer _buffer;
    NSOutputStream *_output;

    NSMutableArray<NSString *> *_tags;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _writer.setAutoFormatting(true);
        _tags = [NSMutableArray array];
    }
    return self;
}

- (BOOL)hasError __attribute__((swift_name("hasError()")))
{
    return _writer.hasError();
}

- (BOOL)setFeatureName:(NSString *)name state:(BOOL)state error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("setFeature(name:state:)")))
{
    return NO; // Not implemented
}

- (BOOL)getFeatureName:(NSString *)name error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("getFeature(name_:)"))) __attribute__((swift_error(nonnull_error)))
{
    return NO; // Not implemented
}

- (BOOL)setPropertyName:(NSString *)name value:(id _Nullable)value error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("setProperty(name:value:)")))
{
    return NO; // Not implemented
}

- (id _Nullable)getPropertyName:(NSString *)name error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("getProperty(name_:)"))) __attribute__((swift_error(nonnull_error)))
{
    return nil; // Not implemented
}

- (BOOL)setOutputFilePath:(NSString *)filePath error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("setOutput(filePath:)")))
{
    _file.setFileName(QString::fromNSString(filePath));
    if (!_file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
        return NO;

    _writer.setDevice(&_file);
    return YES;
}

- (BOOL)setOutputOutput:(nonnull NSOutputStream *)output error:(NSError * _Nullable __autoreleasing * _Nullable)error 
{
    _output = output;
    _buffer.open(QIODevice::ReadWrite);
    _writer.setDevice(&_buffer);
    return YES;
}

- (BOOL)startDocumentEncoding:(NSString * _Nullable)encoding standalone:(OASBoolean * _Nullable)standalone error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("startDocument(encoding:standalone:)")))
{
    _writer.writeStartDocument(QStringLiteral("1.0"), true);
    return YES;
}

- (BOOL)endDocumentAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("endDocument()")))
{
    _writer.writeEndDocument();
    return YES;
}

- (BOOL)setPrefixPrefix:(NSString *)prefix namespace:(NSString *)namespace_ error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("setPrefix(prefix:namespace:)")))
{
    return NO; // Not implemented
}

- (NSString * _Nullable)getPrefixNamespace:(NSString *)namespace_ generatePrefix:(BOOL)generatePrefix error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("getPrefix(namespace:generatePrefix:)"))) __attribute__((swift_error(nonnull_error)))
{
    return nil; // Not implemented
}

- (int32_t)getDepth __attribute__((swift_name("getDepth()")))
{
    return -1; // Not implemented
}

- (NSString * _Nullable)getNamespace __attribute__((swift_name("getNamespace()")))
{
    return nil; // Not implemented
}

- (NSString * _Nullable)getName __attribute__((swift_name("getName()")))
{
    return _tags.lastObject;
}

- (BOOL)startTagNamespace:(NSString * _Nullable)namespace_ name:(NSString *)name error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("startTag(namespace:name:)")))
{
    [_tags addObject:name];
    _writer.writeStartElement(QString::fromNSString(namespace_), QString::fromNSString(name));
    return YES;
}

- (BOOL)attributeNamespace:(NSString * _Nullable)namespace_ name:(NSString *)name value:(NSString *)value error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("attribute(namespace:name:value:)")))
{
    _writer.writeAttribute(QString::fromNSString(namespace_), QString::fromNSString(name), QString::fromNSString(value));
    return YES;
}

- (BOOL)endTagNamespace:(NSString * _Nullable)namespace_ name:(NSString *)name error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("endTag(namespace:name:)")))
{
    [_tags removeLastObject];
    _writer.writeEndElement();
    return YES;
}

- (BOOL)textText:(NSString *)text error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("text(text:)")))
{
    _writer.writeCharacters(QString::fromNSString(text));
    return YES;
}

- (BOOL)textBuf:(OASKotlinCharArray *)buf start:(int32_t)start len:(int32_t)len error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("text(buf:start:len:)")))
{
    return NO; // Not implemented
}

- (BOOL)cdsectText:(NSString *)text error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("cdsect(text:)")))
{
    _writer.writeCDATA(QString::fromNSString(text));
    return YES;
}

- (BOOL)entityRefText:(NSString *)text error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("entityRef(text:)")))
{
    _writer.writeEntityReference(QString::fromNSString(text));
    return YES;
}

- (BOOL)processingInstructionText:(NSString *)text error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("processingInstruction(text:)")))
{
    _writer.writeProcessingInstruction(QString::fromNSString(text));
    return YES;
}

- (BOOL)commentText:(NSString *)text error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("comment(text:)")))
{
    _writer.writeComment(QString::fromNSString(text));
    return YES;
}

- (BOOL)docdeclText:(NSString *)text error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("docdecl(text:)")))
{
    _writer.writeDTD(QString::fromNSString(text));
    return YES;
}

- (BOOL)ignorableWhitespaceText:(NSString *)text error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("ignorableWhitespace(text:)")))
{
    return NO; // Not implemented
}

- (BOOL)flushAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("flush()")))
{
    if (_file.isOpen())
    {
        _file.close();
        return YES;
    }
    else if (_output && _output.streamStatus == NSStreamStatusOpen)
    {
        QByteArray byteArray = _buffer.data();
        const void *data = byteArray.constData();
        NSUInteger length = byteArray.size();

        NSInteger bytesWritten = 0;
        NSUInteger totalBytesWritten = 0;

        while (totalBytesWritten < length)
        {
            bytesWritten = [_output write:(const uint8_t *)data + totalBytesWritten
                               maxLength:length - totalBytesWritten];
            if (bytesWritten == -1)
            {
                NSLog(@"Error writing to output stream: %@", _output.streamError.localizedDescription);
                break;
            }
            totalBytesWritten += bytesWritten;
        }

        if (totalBytesWritten == length)
            return YES;
        else
            NSLog(@"Could not write all data to output stream.");
    }
    else
    {
        NSLog(@"Failed to open output stream: %@", _output.streamError.localizedDescription);
    }

    return NO;
}

@end
