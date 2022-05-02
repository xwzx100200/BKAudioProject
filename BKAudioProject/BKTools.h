//
//  BKTools.h
//  BKAudioProject
//
//  Created by 陈小贝 on 2022/4/27.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BKTools : NSObject

+ (NSData *)convertAudioSamepleBufferToData:(CMSampleBufferRef)sampleBuffer;

/// Add ADTS header
+ (NSData *)adtsDataWithChannels:(NSInteger)channels sampleRate:(NSInteger)sampleRate rawDataLength:(NSInteger)rawDataLength ;

@end

NS_ASSUME_NONNULL_END
