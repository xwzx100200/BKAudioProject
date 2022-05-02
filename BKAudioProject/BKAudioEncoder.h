//
//  BKAudioEncoder.h
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "BKAudioConfig.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BKAudioEncoderDelegate <NSObject>

@optional

- (void)audioEncodeSuccessCallback:(CMSampleBufferRef)sampleBuffer;

- (void)audioEncodeErrorCallback:(NSError *)error;

@end



@interface BKAudioEncoder : NSObject

@property (nonatomic, weak) id<BKAudioEncoderDelegate> delegate;

- (instancetype)initWithConfig:(BKAudioConfig *)config;

- (void)encodeSampleBuffer:(CMSampleBufferRef)buffer; // 编码。
@end

NS_ASSUME_NONNULL_END
