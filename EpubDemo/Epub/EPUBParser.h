//
//  EPUBParser.h
//  EpubDemo
//
//  Created by XuPeng on 16/11/2.
//  Copyright © 2016年 XP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EPUBParser : NSObject

/**
 *  关闭，清空数据
 */
- (void)closeFile;

/**
 *  打开epub
 *
 *  @param fileFullPath epub地址
 *  @param unzipFolder  解压后地址
 *
 *  @return 是否解压成功
 */
- (BOOL)openFilePath:(NSString*)fileFullPath WithUnzipFolder:(NSString*)unzipFolder;

/**
 *  得到opf文件路径（OPF文档是epub电子书的核心文件，且是一个标准的XML文件，依据OPF规范，主要由五个部分组成：<metadata>,元数据信息、<menifest>，文件列表、<spine toc="ncx">，目录、<guide>,指南、<tour>,导读）
 *
 *  @param manifestFileFullPath   文件绝对路径
 *  @param unzipFolder            解压文件夹
 *
 *  @return 返回 opf的文件路径
 */
- (NSString*)opfFilePathWithManifestFile:(NSString*)manifestFileFullPath WithUnzipFolder:(NSString*)unzipFolder;

/**
 *  得到ncx文件路径（目录文件1,通过opf文件得到ncx的位置）
 *
 *  @param opfFilePath   文件绝对路径
 *  @param unzipFolder   解压文件夹
 *
 *  @return 返回 ncx的文件路径
 */
- (NSString*)ncxFilePathWithOpfFile:(NSString*)opfFilePath WithUnzipFolder:(NSString*)unzipFolder;

/**
 *  得到 封面 文件路径
 *
 *  @param opfFilePath   文件绝对路径
 *  @param unzipFolder   解压文件夹
 *
 *  @return 返回 封面的文件路径
 */
- (NSString*)coverFilePathWithOpfFile:(NSString*)opfFilePath WithUnzipFolder:(NSString*)unzipFolder;

/**
 *  得到epub文件 基本信息（作者、标题）
 *
 *  @param opfFilePath   文件绝对路径
 *
 *  @return 返回 基本信息
 */
- (NSMutableDictionary*)epubFileInfoWithOpfFile:(NSString*)opfFilePath;

/**
 *  得到epub文件 目录信息
 *
 *  @param opfFilePath   文件绝对路径
 *
 *  @return 返回 目录信息
 */
- (NSMutableArray*)epubCatalogWithNcxFile:(NSString*)ncxFilePath;

/**
 *  得到epub文件 页码索引
 *
 *  @param opfFilePath   文件绝对路径
 *
 *  @return 返回 页码索引
 */
- (NSMutableArray*)epubPageRefWithOpfFile:(NSString*)opfFilePath;

/**
 *  得到epub文件 页码信息
 *
 *  @param opfFilePath   文件绝对路径
 *
 *  @return 返回 页码信息
 */
- (NSMutableArray*)epubPageItemWithOpfFile:(NSString*)opfFilePath;

/**
 *  html内容 ＋ js内容 ＝ 新的html内容 将js内容插入到第一个head后面 这个js的作用是让图片正确的显示在屏幕上
 *
 *  @param fileFullPath   文件html绝对路径
 *  @param jsContent      脚本js内容
 *
 *  @return 返回 整理后html内容
 */
- (NSString*)HTMLContentFromFile:(NSString*)fileFullPath AddJsContent:(NSString*)jsContent;

@end
