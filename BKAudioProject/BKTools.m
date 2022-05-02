//
//  BKTools.m
//  BKAudioProject
//
//  Created by 陈小贝 on 2022/4/27.
//

#import "BKTools.h"

@implementation BKTools

//将sampleBuffer数据提取出PCM数据返回给ViewController.可以直接播放PCM数据
+ (NSData *)convertAudioSamepleBufferToData: (CMSampleBufferRef)sampleBuffer {
    /*
    //获取pcm数据大小
    size_t size = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    
    //分配size大小的空间
    int8_t *audio_data = (int8_t *)malloc(size);
    //初始化分配到的空间（用0去填充空间）
    memset(audio_data, 0, size);
    
    //获取CMBlockBuffer, 这里面保存了PCM数据
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    //将数据copy到我们分配的空间中
    CMBlockBufferCopyDataBytes(blockBuffer, 0, size, audio_data);
    //PCM data->NSData
    NSData *data = [NSData dataWithBytes:audio_data length:size];
    free(audio_data);
    return data;
    */
    
    
    CMBlockBufferRef blockBuffer1 = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t totolLength;
    char *dataPointer = NULL;
    CMBlockBufferGetDataPointer(blockBuffer1, 0, NULL, &totolLength, &dataPointer);
    if (totolLength == 0 || !dataPointer) {
        NSLog(@"解码不出data");
        return nil;
    }
    NSData *data1 = [NSData dataWithBytes:dataPointer length:totolLength];
    return data1;
}

// 按音频参数生产 AAC packet 对应的 ADTS 头数据。
// 当编码器编码的是 AAC 裸流数据时，需要在每个 AAC packet 前添加一个 ADTS 头用于解码器解码音频流。
// 参考文档：
// ADTS 格式参考：http://wiki.multimedia.cx/index.php?title=ADTS
// MPEG-4 Audio 格式参考：http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
+ (NSData *)adtsDataWithChannels:(NSInteger)channels sampleRate:(NSInteger)sampleRate rawDataLength:(NSInteger)rawDataLength {
    // 1、创建数据缓冲区。
    int adtsLength = 7; // ADTS 头固定 7 字节。
    char *packet = malloc(sizeof(char) * adtsLength);
    
    // 2、设置各数据字段。
    int profile = 2; // 2 表示 AAC LC。
    NSInteger sampleRateIndex = [self.class sampleRateIndex:sampleRate]; // 取得采样率对应的 index。
    int channelCfg = (int) channels; // MPEG-4 Audio Channel Configuration。
    NSUInteger fullLength = adtsLength + rawDataLength; // 这里的长度字段是：ADTS 头数据和 AAC packet 数据的总长度。
    
    //  3、填充 ADTS 数据。
    packet[0] = (char) 0xFF; // 11111111     = syncword
    packet[1] = (char) 0xF9; // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char) (((profile - 1) << 6) + (sampleRateIndex << 2) + (channelCfg >> 2));
    packet[3] = (char) (((channelCfg & 3) << 6) + (fullLength >> 11));
    packet[4] = (char) ((fullLength & 0x7FF) >> 3);
    packet[5] = (char) (((fullLength & 7) << 5) + 0x1F);
    packet[6] = (char) 0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    
    return data;
}

// 音频采样率对应的 index。
+ (NSInteger)sampleRateIndex:(NSInteger)frequencyInHz {
    NSInteger sampleRateIndex = 0;
    switch (frequencyInHz) {
        case 96000:
            sampleRateIndex = 0;
            break;
        case 88200:
            sampleRateIndex = 1;
            break;
        case 64000:
            sampleRateIndex = 2;
            break;
        case 48000:
            sampleRateIndex = 3;
            break;
        case 44100:
            sampleRateIndex = 4;
            break;
        case 32000:
            sampleRateIndex = 5;
            break;
        case 24000:
            sampleRateIndex = 6;
            break;
        case 22050:
            sampleRateIndex = 7;
            break;
        case 16000:
            sampleRateIndex = 8;
            break;
        case 12000:
            sampleRateIndex = 9;
            break;
        case 11025:
            sampleRateIndex = 10;
            break;
        case 8000:
            sampleRateIndex = 11;
            break;
        case 7350:
            sampleRateIndex = 12;
            break;
        default:
            sampleRateIndex = 15;
    }
    
    return sampleRateIndex;
}

@end
