//
//  ViewController.m
//  BKAudioProject
//
//  Created by 陈小贝 on 2022/4/27.
//

#import "ViewController.h"
#import "BKAudioCapture.h"
#import "BKTools.h"
#import "BKPcmPlayer.h"
#import "BKAudioEncoder.h"
#import "BKAudioDecoder.h"

@interface ViewController ()<BKAudioDecoderDelegate, BKAudioEncoderDelegate>
@property (nonatomic, strong) BKAudioCapture *audioCapture;
@property (nonatomic, strong) BKPcmPlayer *player;
@property (nonatomic, strong) BKAudioDecoder *audioDecode;
@property (nonatomic, strong) BKAudioEncoder *audioEncode;

@property (nonatomic, strong) NSFileHandle *handle;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSMutableArray *aacDataArr;
@property (nonatomic, strong) NSMutableData *pcmData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"音频采集-编码-解码-播放");
    self.aacDataArr = [[NSMutableArray alloc]init];
    self.pcmData = [NSMutableData data];
    [self createFile];
    [self setupAudioSession];
    self.player = [[BKPcmPlayer alloc]initWithConfig:[BKAudioConfig defaultConifg]];
    self.audioCapture = [[BKAudioCapture alloc]initWithConfig:[BKAudioConfig defaultConifg]];
    __weak typeof(self)weakSelf = self;
    self.audioCapture.sampleBufferOutputCallBack = ^(CMSampleBufferRef  _Nonnull sampleBuffer) {
        //1、这里的sampleBuffer拿到的就是pcm数据啦，可以直接存本地或者直接播放。（如果不想做网络传输的话，其实可以不用编码[压缩]的）
        /*NSData *pcmData = [BKTools convertAudioSamepleBufferToPcmData:sampleBuffer];
        [weakSelf.pcmData appendData:pcmData];
        //NSLog(@"pcmData保存成功");*/
        
        // 2、编码成AAC格式
        NSData *pcmData = [BKTools convertAudioSamepleBufferToData:sampleBuffer];
        NSLog(@"每次采集到数据的大小%ld",pcmData.length);
        [weakSelf.audioEncode encodeSampleBuffer:sampleBuffer];
    };

    self.audioCapture.errorCallBack = ^(NSError * _Nonnull error) {
        NSLog(@"%@",error.description);
    };
}

- (void)setupAudioSession {
    NSError *error = nil;
    
    // 1、获取音频会话实例。
    AVAudioSession *session = [AVAudioSession sharedInstance];

    // 2、设置分类和选项。
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    if (error) {
        NSLog(@"AVAudioSession setCategory error.");
        error = nil;
        return;
    }
    
    // 3、设置模式。
    [session setMode:AVAudioSessionModeVideoRecording error:&error];
    if (error) {
        NSLog(@"AVAudioSession setMode error.");
        error = nil;
        return;
    }

    // 4、激活会话。
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"AVAudioSession setActive error.");
        error = nil;
        return;
    }
}

- (void)createFile {
    self.path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"aacAudio.aac"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:self.path]) {
        if ([manager removeItemAtPath:self.path error:nil]) {
            NSLog(@"删除成功");
            if ([manager createFileAtPath:self.path contents:nil attributes:nil]) {
                NSLog(@"创建文件");
            }
        }
    }else {
        if ([manager createFileAtPath:self.path contents:nil attributes:nil]) {
            NSLog(@"创建文件");
        }
    }
    
    NSLog(@"%@", _path);
    self.handle = [NSFileHandle fileHandleForWritingAtPath:self.path];
}


- (IBAction)start:(UIButton *)sender {
    [self.audioCapture startRunning];
}

- (IBAction)stop:(UIButton *)sender {
   [self.audioCapture stopRunning];
}

- (IBAction)closeFile:(UIButton *)sender {
    [self.handle closeFile];
}

- (IBAction)decodeAndPlay:(UIButton *)sender {
    NSLog(@"播放本地aac文件");
    /*
    // 1、拿到音频保存的aac文件数据
    NSString * path = [[NSBundle mainBundle]pathForResource:@"bkAudio" ofType:@"aac"];
    NSLog(@"%@",path);
    NSData *data = [NSData dataWithContentsOfFile:path];
    // 2、decode转成pcm数据，播放。
    [self.audioDecode decodeAudioAACData:data];
     */
    
    //3、一小段一小段的解码aac数据为pcm
    /*for (NSData *aacData in self.aacDataArr) {
        [self.audioDecode decodeAudioAACData:aacData];
    }*/
    
    
    //4、播放全部完整pcm
    [self.player playPCMData:self.pcmData];
}

- (void)captureOutput:(BKAudioCapture *)capture didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // 1、这里的sampleBuffer拿到的就是pcm数据啦，可以直接存本地或者直接播放。（如果不想做网络传输的话，其实可以不用编码[压缩]的）
    /*NSData *pcmData = [BKTools convertAudioSamepleBufferToPcmData:sampleBuffer];
    [self.pcmData appendData:pcmData];*/
    
    // 2、编码成AAC格式
    NSData *pcmData = [BKTools convertAudioSamepleBufferToData:sampleBuffer];
    NSLog(@"每次采集到数据的大小%ld",pcmData.length);
    [self.audioEncode encodeSampleBuffer:sampleBuffer];
    
}

#pragma mark - BKEncodeAudioDelegate

- (void)audioEncodeSuccessCallback:(CMSampleBufferRef)sampleBuffer {
    //1.写入文件，再播放整个aac文件
    /*NSData *aacData = [BKTools convertAudioSamepleBufferToData:sampleBuffer];
    AudioStreamBasicDescription audioFormat = *CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer));
    NSData *adtsData = [BKTools adtsDataWithChannels:audioFormat.mChannelsPerFrame sampleRate:audioFormat.mSampleRate rawDataLength:aacData.length];
    NSMutableData *totalData = [NSMutableData dataWithData:adtsData];
    [totalData appendData:aacData];
    if (aacData) {
        [_handle seekToEndOfFile];
        [_handle writeData:totalData];
    }*/
    
    //2、解码为pcm数据，播放
    [self.audioDecode decodeSampleBuffer:sampleBuffer];
}

- (void)audioEncodeErrorCallback:(NSError *)error {
    NSLog(@"%@",error.description);
}

#pragma mark - BKDecodeAudioDelegate

- (void)audioDecodeSuccessCallback:(CMSampleBufferRef)sampleBuffer {
    
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t totolLength;
    char *dataPointer = NULL;
    CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totolLength, &dataPointer);
    if (totolLength == 0 || !dataPointer) {
        return;
    }
    NSData *data = [NSData dataWithBytes:dataPointer length:totolLength];
    
    [self.pcmData appendData:data];
}

- (void)audioDecodeErrorCallback:(NSError *)error {
    NSLog(@"%@",error.description);
}


- (BKAudioEncoder *)audioEncode {
    if (!_audioEncode) {
        _audioEncode = [[BKAudioEncoder alloc]initWithConfig:[BKAudioConfig defaultConifg]];
        _audioEncode.delegate = self;
    }
    return _audioEncode;
}

- (BKAudioDecoder *)audioDecode {
    if (!_audioDecode) {
        _audioDecode = [[BKAudioDecoder alloc]init];
        _audioDecode.delegate = self;
    }
    return _audioDecode;
}

@end
