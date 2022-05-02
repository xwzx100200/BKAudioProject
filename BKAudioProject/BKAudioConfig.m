//
//  BKAudioConfig.m
//  BKAudioProject
//
//  Created by 陈小贝 on 2022/4/27.
//

#import "BKAudioConfig.h"

@implementation BKAudioConfig
+ (instancetype)defaultConifg {
    return  [[BKAudioConfig alloc] init];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bitrate = 96000;
        self.channelCount = 2;
        self.sampleSize = 16;
        self.sampleRate = 44100;
    }
    return self;
}
@end
