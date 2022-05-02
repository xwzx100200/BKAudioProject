//
//  BKPcmPlayer.h
//  BKAudioProject
//
//  Created by 陈小贝 on 2022/4/27.
//

#import <Foundation/Foundation.h>
#import "BKAudioConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface BKPcmPlayer : NSObject

- (instancetype)initWithConfig:(BKAudioConfig *)config;
/**播放pcm*/
- (void)playPCMData:(NSData *)data;
/** 设置音量增量 0.0 - 1.0 */
- (void)setupVoice:(Float32)gain;
/**销毁 */
- (void)dispose;

@end

NS_ASSUME_NONNULL_END
