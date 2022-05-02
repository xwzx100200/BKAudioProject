//
//  BKAudioConfig.h
//  BKAudioProject
//
//  Created by 陈小贝 on 2022/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BKAudioConfig : NSObject
/**编码率*/
@property (nonatomic, assign) NSInteger bitrate;//96000）
/**声道*/
@property (nonatomic, assign) NSInteger channelCount;//（1）
/**采样率*/
@property (nonatomic, assign) NSInteger sampleRate;//(默认44100)
/**采样点量化*/
@property (nonatomic, assign) NSInteger sampleSize;//(16bit)

+ (instancetype)defaultConifg;

@end

NS_ASSUME_NONNULL_END
