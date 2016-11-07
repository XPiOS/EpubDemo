//
//  EPUBParser.m
//  EpubDemo
//
//  Created by XuPeng on 16/11/2.
//  Copyright © 2016年 XP. All rights reserved.
//

#import "EPUBParser.h"
#import "ZipArchive.h"
#import "GDataXMLNode.h"

@implementation EPUBParser

- (BOOL)openFilePath:(NSString *)fileFullPath WithUnzipFolder:(NSString *)unzipFolder {
    
    // 1、判断目标文件是否存在、解压地址是否存在
    if (![self isFileExist:fileFullPath]) {
        return NO;
    }
    // 2、解压epub
    if ([self unzipWithFileFullPath:fileFullPath WithUnzipFolder:unzipFolder]) {
        return YES;
    }
    return NO;
}

- (NSString *)opfFilePathWithManifestFile:(NSString *)manifestFileFullPath WithUnzipFolder:(NSString *)unzipFolder {
    NSString *opfFileFullPath = nil;
    NSData *xmlData           = [[NSData alloc] initWithContentsOfFile:manifestFileFullPath];
    if (xmlData) {
        NSError *err = nil;
        // 读取xml
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        if ([err code] == 0) {
            //根节点
            GDataXMLElement *root = [doc rootElement];
            // 读取key为full-path的值
            NSArray *nodes        = [root nodesForXPath:@"//@full-path[1]" error:nil];
            if ([nodes count]>0) {
                GDataXMLElement *opfNode = nodes[0];
                opfFileFullPath          = [NSString stringWithFormat:@"%@/%@",unzipFolder,[opfNode stringValue]];
            }
        }
    }
    return opfFileFullPath;
}

- (NSString *)ncxFilePathWithOpfFile:(NSString *)opfFilePath WithUnzipFolder:(NSString *)unzipFolder {
    NSString *ncxFileName = nil;
    NSData *xmlData       = [[NSData alloc] initWithContentsOfFile:opfFilePath];
    if (xmlData) {
        NSError *err                = nil;
        GDataXMLDocument *opfXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        if ([err code] == 0) {
            //根节点
            GDataXMLElement *root           = [opfXmlDoc rootElement];
            NSError *errXPath               = nil;
            NSDictionary *namespaceMappings = [NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"];
            NSArray* itemsArray             = [root nodesForXPath:@"//opf:item[@id='ncx']" namespaces:namespaceMappings error:&errXPath];
            if ([itemsArray count] < 1) {
                itemsArray = [root nodesForXPath:@"//item[@id='ncx']" namespaces:namespaceMappings error:&errXPath];
            }
            if ([itemsArray count] > 0) {
                GDataXMLElement *element = itemsArray[0];
                NSString *itemhref       = [[element attributeForName:@"href"] stringValue];
                ncxFileName              = itemhref;
            }
        }
    }
    if (ncxFileName && [ncxFileName length]>0)
    {
        NSInteger lastSlash       = [opfFilePath rangeOfString:@"/" options:NSBackwardsSearch].location;
        NSString *ebookBasePath   = [opfFilePath substringToIndex:(lastSlash +1)];
        NSString *ncxFileFullPath = [NSString stringWithFormat:@"%@%@", ebookBasePath, ncxFileName];
        return ncxFileFullPath;
    }
    return nil;
    
}

- (NSString *)coverFilePathWithOpfFile:(NSString *)opfFilePath WithUnzipFolder:(NSString *)unzipFolder{
    NSString *coverFileName = nil;
    NSData *xmlData         = [[NSData alloc] initWithContentsOfFile:opfFilePath];
    if (xmlData) {
        NSError *err                = nil;
        GDataXMLDocument *opfXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        if ([err code] == 0) {
            GDataXMLElement *root           = [opfXmlDoc rootElement];
            NSError *errXPath               = nil;
            NSDictionary *namespaceMappings = [NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"];
            NSArray* itemsArray = [root nodesForXPath:@"//opf:item[@id='cover']" namespaces:namespaceMappings error:&errXPath];
            if ([itemsArray count] < 1) {
                itemsArray = [root nodesForXPath:@"//item[@id='cover']" namespaces:namespaceMappings error:&errXPath];
            }
            if ([itemsArray count]>0) {
                GDataXMLElement *element = itemsArray[0];
                NSString *itemhref       = [[element attributeForName:@"href"] stringValue];
                coverFileName            = itemhref;
            }
        }
    }
    if (coverFileName && [coverFileName length]>0) {
        NSInteger lastSlash         = [opfFilePath rangeOfString:@"/" options:NSBackwardsSearch].location;
        NSString *ebookBasePath     = [opfFilePath substringToIndex:(lastSlash +1)];
        NSString *coverFileFullPath = [NSString stringWithFormat:@"%@%@", ebookBasePath, coverFileName];
        return coverFileFullPath;
    }
    return nil;
}
- (NSMutableDictionary *)epubFileInfoWithOpfFile:(NSString *)opfFilePath {
    NSMutableDictionary *epubInfo = nil;
    NSData *xmlData               = [[NSData alloc] initWithContentsOfFile:opfFilePath];
    if (xmlData) {
        NSError *err                = nil;
        GDataXMLDocument *opfXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        if ([err code] == 0) {
            GDataXMLElement *root           = [opfXmlDoc rootElement];
            NSError *errXPath               = nil;
            NSDictionary *namespaceMappings = [NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"];
            NSArray* itemsMetadata          = [root nodesForXPath:@"//opf:metadata" namespaces:namespaceMappings error:&errXPath];
            if ([itemsMetadata count] > 0) {
                epubInfo                      = [NSMutableDictionary dictionary];
                GDataXMLElement *nodeMetadata = itemsMetadata[0];
                for (GDataXMLElement *child in [nodeMetadata children]) {
                    NSString *nodeName  = [child name];
                    NSString *nodeValue = [child stringValue];
                    [epubInfo setObject:nodeValue forKey:nodeName];
                }
            }
        }
    }
    return epubInfo;
}

- (NSMutableArray *)epubCatalogWithNcxFile:(NSString *)ncxFilePath {
    NSMutableArray *arrCatalog = nil;
    NSData *xmlData            = [[NSData alloc] initWithContentsOfFile:ncxFilePath];
    if (xmlData) {
        NSError *err                = nil;
        GDataXMLDocument *ncxXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        if ([err code] == 0) {
            arrCatalog                  = [NSMutableArray array];
            GDataXMLElement *root       = [ncxXmlDoc rootElement];
            NSDictionary *dictNameSpace = [NSDictionary dictionaryWithObject:@"http://www.daisy.org/z3986/2005/ncx/" forKey:@"ncx"];
            NSError *errXPath           = nil;
            NSArray *navPoints          = [root nodesForXPath:@"ncx:navMap/ncx:navPoint" namespaces:dictNameSpace error:&errXPath];
            for (GDataXMLElement *navPoint in navPoints) {
                NSString *id1       = [[navPoint attributeForName:@"id"] stringValue];
                NSString *playOrder = [[navPoint attributeForName:@"playOrder"] stringValue];
                NSArray *textNodes  = [navPoint nodesForXPath:@"ncx:navLabel/ncx:text" namespaces:dictNameSpace error:nil];
                NSString *ncx_text  = @"";
                if ([textNodes count] > 0) {
                    GDataXMLElement *nodeLabel = textNodes[0];
                    ncx_text                   = [nodeLabel stringValue];
                }
                NSArray *contentNodes = [navPoint nodesForXPath:@"ncx:content" namespaces:dictNameSpace error:nil];
                NSString *ncx_src     = @"";
                if ([contentNodes count] > 0) {
                    GDataXMLElement *nodeContent = contentNodes[0];
                    ncx_src                      = [[nodeContent attributeForName:@"ncx:src"] stringValue];
                }
                NSMutableDictionary *oneChapter = [NSMutableDictionary dictionary];
                [oneChapter setObject:[id1 length]>0?id1:@"" forKey:@"id"];
                [oneChapter setObject:[playOrder length]>0?playOrder:@"" forKey:@"playOrder"];
                [oneChapter setObject:[ncx_text length]>0?ncx_text:@"" forKey:@"text"];
                [oneChapter setObject:[ncx_src length]>0?ncx_src:@"" forKey:@"src"];
                [arrCatalog addObject:oneChapter];
            }
        }
    }
    return arrCatalog;
}

- (NSMutableArray *)epubPageRefWithOpfFile:(NSString *)opfFilePath {
    NSMutableArray *arrPageRef = nil;
    NSData *xmlData            = [[NSData alloc] initWithContentsOfFile:opfFilePath];
    if (xmlData) {
        NSError *err                = nil;
        GDataXMLDocument *opfXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        if ([err code] == 0) {
            GDataXMLElement *root           = [opfXmlDoc rootElement];
            NSError *errXPath               = nil;
            NSDictionary *namespaceMappings = [NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"];
            NSArray* itemRefsArray          = [root nodesForXPath:@"//opf:itemref" namespaces:namespaceMappings error:&errXPath];
            if(itemRefsArray.count < 1) {
                NSString* xpath = [NSString stringWithFormat:@"//spine[@toc='ncx']/itemref"];
                itemRefsArray   = [root nodesForXPath:xpath namespaces:namespaceMappings error:&errXPath];
            }
            arrPageRef = [NSMutableArray array];
            for (GDataXMLElement* element in itemRefsArray) {
                NSString *idref1 = [[element attributeForName:@"idref"] stringValue];
                if (idref1 && [idref1 length] > 0) {
                    [arrPageRef addObject:idref1];
                }
            }
        }
    }
    return arrPageRef;
}

- (NSMutableArray *)epubPageItemWithOpfFile:(NSString *)opfFilePath {
    NSMutableArray *arrPageItem = nil;
    NSData *xmlData             = [[NSData alloc] initWithContentsOfFile:opfFilePath];
    if (xmlData) {
        NSError *err                = nil;
        GDataXMLDocument *opfXmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&err];
        if ([err code] == 0) {
            GDataXMLElement *root = [opfXmlDoc rootElement];
            NSError *errXPath               = nil;
            NSDictionary *namespaceMappings = [NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"];
            NSArray* itemsArray             = [root nodesForXPath:@"//opf:item" namespaces:namespaceMappings error:&errXPath];
            if ([itemsArray count] < 1) {
                itemsArray = [root nodesForXPath:@"//item" namespaces:namespaceMappings error:&errXPath];
            }
            arrPageItem = [NSMutableArray array];
            for (GDataXMLElement *element in itemsArray) {
                NSString *itemID   = [[element attributeForName:@"id"] stringValue];
                NSString *itemhref = [[element attributeForName:@"href"] stringValue];
                if ([itemID length] > 0 && [itemhref length] > 0) {
                    NSMutableDictionary *page1 = [NSMutableDictionary dictionary];
                    [page1 setObject:itemID forKey:@"id"];
                    [page1 setObject:itemhref forKey:@"href"];
                    [arrPageItem addObject:page1];
                }
            }
        }
    }
    return arrPageItem;
}
- (NSString *)HTMLContentFromFile:(NSString *)fileFullPath AddJsContent:(NSString *)jsContent {
    NSString *strHTML        = nil;
    NSError *error           = nil;
    NSStringEncoding encoding;
    NSString *strFileContent = [[NSString alloc] initWithContentsOfFile:fileFullPath usedEncoding:&encoding error:&error];
    if (strFileContent && [jsContent length] > 1) {
        NSRange head1 = [strFileContent rangeOfString:@"<head>" options:NSCaseInsensitiveSearch];
        NSRange head2 = [strFileContent rangeOfString:@"</head>" options:NSCaseInsensitiveSearch];
        if (head1.location != NSNotFound && head2.location != NSNotFound && head2.location > head1.location) {
            NSRange rangeHead     = head1;
            rangeHead.length      = head2.location - head1.location;
            NSString *strHead     = [strFileContent substringWithRange:rangeHead];
            NSString *str1        = [strFileContent substringToIndex:head1.location];
            NSString *str3        = [strFileContent substringFromIndex:head2.location];
            NSString *strHeadEdit = [NSString stringWithFormat:@"%@\n%@",strHead,jsContent];
            strHTML               = [NSString stringWithFormat:@"%@%@%@",str1,strHeadEdit,str3];
        }
    } else if (strFileContent) {
        strHTML = [NSString stringWithFormat:@"%@",strFileContent];
    }
    return strHTML;
}

#pragma mark - 内部方法
#pragma mark 判断文件是否存在
- (BOOL)isFileExist:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}
#pragma mark 解压
- (int)unzipWithFileFullPath:(NSString*)fileFullPath WithUnzipFolder:(NSString *)unzipFolder {
    ZipArchive* za = [[ZipArchive alloc] init];
    if( [za UnzipOpenFile:fileFullPath]) {
        if ([self isFileExist:unzipFolder]) {
            // 目录存在，就删除目录里面所有文件
            [self deleteDirectory:unzipFolder DelSelf:NO];
        } else {
            // 目录不存在，就创建
            [self createDirectory:unzipFolder];
        }
        BOOL bUnZip = [za UnzipFileTo:[NSString stringWithFormat:@"%@/",unzipFolder] overWrite:YES];
        [za UnzipCloseFile];
        return bUnZip;
    }
    return NO;
}
#pragma mark 创建文件夹
- (BOOL)createDirectory:(NSString*)strFolderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:strFolderPath]) {
        return [fileManager createDirectoryAtPath:strFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return YES;
}
#pragma mark 删除文件(是否删除自身)
- (BOOL)deleteDirectory:(NSString*)strFolderPath DelSelf:(BOOL)bDelSelf {
    BOOL bDo1 = YES;
    NSFileManager *localFileManager = [NSFileManager defaultManager];
    if (bDelSelf) {
        //删除自身
        if (![localFileManager removeItemAtPath:strFolderPath error:nil]) {
            bDo1 = NO;
        }
    } else {
        //不删除自身
        NSDirectoryEnumerator *dirEnum = [localFileManager enumeratorAtPath:strFolderPath];
        NSString *file;
        while (file = [dirEnum nextObject]) {
            NSString *delPath = [strFolderPath stringByAppendingPathComponent:file];
            if (![localFileManager removeItemAtPath:delPath error:nil]) {
                bDo1=NO;
            }
        }
    }
    return bDo1;
}
@end
