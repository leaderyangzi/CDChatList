//
//  CellCaculator.m
//  CDChatList
//
//  Created by chdo on 2017/10/26.
//

#import "CellCaculator.h"
#import "ChatMacros.h"
#import "CDBaseMsgCell.h"
#import "CTData.h"
#import "ChatHelpr.h"
#import "UITool.h"

@interface CellCaculator()

@end

@implementation CellCaculator


+(void)caculatorAllCellHeight: (CDChatMessageArray)msgArr
         callBackOnMainThread: (void(^)(CGFloat))completeBlock{
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t  queue = dispatch_get_global_queue(0, 0);
    // 此处为同步计算所有高度
    for (int i = 0; i < msgArr.count; i++) {
        dispatch_group_async(group, queue, ^{
            [self fetchCellHeight:i of:msgArr];
        });
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 总共高度
        CGFloat totalHeight = 0.0f;
        for (CDChatMessage msg in msgArr) {
            totalHeight = totalHeight + msg.cellHeight;
        }
        completeBlock(totalHeight);
    });
}

//TODO: 获取cell的高度方式
+(CGFloat)fetchCellHeight:(NSUInteger)index of:(CDChatMessageArray)msgArr{
    
    CDChatMessage data = msgArr[index];
    // 返回缓存中的高度
    // cell的高度会被保存，textlayout 目前还没有保存方案，
    if (data.cellHeight && data.textlayout) {
        return data.cellHeight;
    }
    
//     计算高度
    // 和上一条信息对比判断cell上是否显示时间label
    if (index > 0) {
        CDChatMessage previousData = msgArr[index - 1];
        NSInteger lastTime = [previousData.createTime integerValue];
        NSInteger currentTime = [data.createTime integerValue];
        data.willDisplayTime = ((currentTime - lastTime) > 180000); // 3分钟
    }
    CGSize res = [self caculateCellHeightAndBubleWidth:data];
    
    // 记录 缓存
    data.bubbleWidth = res.width;
    
    // 加上可能显示的时间视图高度
    CGFloat height = res.height;
    
    data.cellHeight = height + (data.willDisplayTime ? (data.msgType != CDMessageTypeSystemInfo ? MsgTimeH : 0) : 0);
    
    return data.cellHeight;
}

#pragma mark 针对不同的cell，计算cell高度及气泡宽度

/**
 针对不同的cell，计算cell高度及气泡宽度
 
 @param data 消息模型
 @return cell高度
 */
+(CGSize)caculateCellHeightAndBubleWidth:(CDChatMessage)data{

    switch (data.msgType) {
        case CDMessageTypeText:
            return [self sizeForTextMessage:data];
        case CDMessageTypeImage:
            return [self sizeForImageMessage:data];
        case CDMessageTypeSystemInfo:
            return [self sizeForSysInfoMessage:data];
        case CDMessageTypeAudio:
            return [self sizeForAudioMessage:data];
        default:
            return CGSizeMake(150, 170);
    }
}

#pragma mark ---计算文字消息尺寸方法
+(CGSize) sizeForTextMessage:(CDChatMessage)msgData{
    
    NSMutableAttributedString *msg_attributeText;

    if (msgData.msg) {
        msg_attributeText = [[NSMutableAttributedString alloc] initWithString: msgData.msg];
    }else{
        msg_attributeText = [[NSMutableAttributedString alloc] initWithString: @""];
    }
    
    // 文字的限制区域，红色部分
    CGSize maxTextSize = CGSizeMake(BubbleMaxWidth - BubbleSharpAnglehorizInset - BubbleRoundAnglehorizInset,
                                    CGFLOAT_MAX);
    
    CTData *data = [CTData dataWithStr:msgData.msg containerWithSize:maxTextSize configuration:[ChatHelpr defaultConfiguration].ctDataconfig];
    
    msgData.textlayout = data;
    
    // 计算气泡宽度
    CGFloat bubbleWidth = ceilf(data.width) + BubbleSharpAnglehorizInset + BubbleRoundAnglehorizInset;
    // 计算整个cell高度
    CGFloat cellheight = ceilf(data.height) + BubbleRoundAnglehorizInset * 2 + MessageMargin * 2;

    // 如果 cellheight小于最小cell高度
    if (cellheight < MessageContentH) {
        cellheight = MessageContentH;
    }
    
    return CGSizeMake(bubbleWidth, cellheight);
}

#pragma mark ---计算图片消息尺寸方法

/**
 根据图片大小计算气泡宽度和cell高度
 */
 CGSize caculateImageSize140By140(UIImage *image) {
    
    // 图片将被限制在140*140的区域内，按比例显示
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    
    CGFloat maxSide = MAX(width, height);
    CGFloat miniSide = MIN(width, height);
    
    // 按比例缩小后的小边边长
    CGFloat actuallMiniSide = 140 * miniSide / maxSide;
    
    // 防止长图，宽图，限制最小边 下限
    if (actuallMiniSide < 80) {
        actuallMiniSide = 80;
    }
    
    // 返回的高度是图片高度，需加上消息内边距变成消息体高度
    if (maxSide == width) {
        return CGSizeMake(140, actuallMiniSide + MessageMargin * 2);
    } else {
        return CGSizeMake(actuallMiniSide, 140 + MessageMargin * 2);
    }
}

+(CGSize) sizeForImageMessage: (CDChatMessage)msgData {
    
    // 获得本地缓存的图片
    UIImage *image = [[SDImageCache sharedImageCache] imageFromCacheForKey: msgData.msg];
    if (!image) {
        image = [[SDImageCache sharedImageCache] imageFromCacheForKey: msgData.messageId];
    }
    // 如果本地存在图片，则通过图片计算
    if (image) {
        return caculateImageSize140By140(image);
    } else {
        // 若不存在，则返回占位图大小，并下载
        if (msgData.msgState != CDMessageStateSendFaild) {
            msgData.msgState = CDMessageStateDownloading;
        }
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:msgData.msg] options:SDWebImageDownloaderUseNSURLCache progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {

        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
            if(error){
                msgData.msgState = CDMessageStateDownloadFaild;
                [[NSNotificationCenter defaultCenter] postNotificationName:CHATLISTDOWNLOADLISTFINISH
                                                                    object:msgData
                                                                  userInfo:error.userInfo];
            } else {

                CGSize size = caculateImageSize140By140(image);
                [[SDImageCache sharedImageCache] storeImage:image forKey:msgData.msg completion:nil];

                msgData.bubbleWidth = size.width;
                // 加上可能显示的时间视图高度
                CGFloat height = size.height;
                msgData.cellHeight = height + (msgData.willDisplayTime ? MsgTimeH : 0);

                msgData.msgState = CDMessageStateNormal;
                [[NSNotificationCenter defaultCenter] postNotificationName:CHATLISTDOWNLOADLISTFINISH
                                                                    object:msgData
                                                                  userInfo:nil];
            }
        }];
        return CGSizeMake(140, 140);
    }
}
#pragma mark ---计算系统消息消息尺寸方法

+(CGSize)sizeForSysInfoMessage:(CDChatMessage)msgData{
    
    NSDictionary *attri = @{NSFontAttributeName: SysInfoMessageFont};
    CGSize maxTextSize = CGSizeMake(SysInfoMessageMaxWidth, CGFLOAT_MAX);
    CGSize caculateTextSize = [msgData.msg boundingRectWithSize: maxTextSize
                                                        options: NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                     attributes:attri context:nil].size;
    
    CGFloat height = caculateTextSize.height + SysInfoPadding * 2;
    return CGSizeMake(caculateTextSize.width + SysInfoPadding * 2 + 10, height);
}

#pragma mark ---计算音频消息消息尺寸方法
+(CGSize)sizeForAudioMessage:(CDChatMessage)msgData{
    
    return CGSizeMake(200, MessageContentH);
}

@end
