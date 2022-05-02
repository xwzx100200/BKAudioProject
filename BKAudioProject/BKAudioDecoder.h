//
//  KFAudioDecoder.h
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BKAudioDecoderDelegate <NSObject>

- (void)audioDecodeSuccessCallback:(CMSampleBufferRef)sampleBuffer;

- (void)audioDecodeErrorCallback:(NSError *)error;

@end

@interface BKAudioDecoder : NSObject
@property (nonatomic, weak)id <BKAudioDecoderDelegate>delegate;

- (void)decodeSampleBuffer:(CMSampleBufferRef)sampleBuffer; // 解码。
@end

NS_ASSUME_NONNULL_END
