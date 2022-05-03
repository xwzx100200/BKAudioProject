# BKAudioProject

该项目是包括了音频的录制、编码（AAC）、解码（PCM）全部过程；是使用AVFoundation、AudioToolBox的框架写的OC代码。
#### 一、流程说明
该项目是包括了音频的录制、编码（AAC）、解码（PCM）全部过程；是使用AVFoundation、AudioToolBox的框架写的OC代码。
项目通过苹果API获取的是PCM流数据，这是一个最原始的模拟信号转数字信号的数据，可以直接播放的。当是由于是原始的数据，非常大，不利于传输，所以要压缩，去掉一些冗余的数据。
所谓的编码就是把原始的PCM数据压缩成其他格式的数据，比如AAC、MP3等。一般都是编码成AAC数据（AAC数据在相同的压缩条件下比MP3好）。
而播放AAC数据就是把AAC解码还原成PCM数据进行播放。
#### 二、代码Api说明
##### 1、采集流程Api说明
AudioComponent：表示音频组件。一种音频组件通常由 type、subtype、manufacturer 三属性来唯一标识。
AudioComponentDescription：表示音频组件的描述。其中 type、subtype、manufacturer 三属性组合起来标识一种音频组件。
```
AudioComponentDescription acd = {
    .componentType = kAudioUnitType_Output,
    .componentSubType = kAudioUnitSubType_RemoteIO,
    .componentManufacturer = kAudioUnitManufacturer_Apple,
    .componentFlags = 0,
    .componentFlagsMask = 0,
};
```
AudioComponentInstance：表示音频组件的实例。
AudioComponentFindNext(...)：用于查找符合描述的音频组件。
AudioComponentGetDescription(...)：用于获取一种音频组件对应的描述。
AudioComponentInstanceNew(...)：创建一个音频组件实例。
AudioComponentInstanceDispose(...)：释放一个音频组件实例。
```
// 2、查找符合指定描述的音频组件。
    AudioComponent component = AudioComponentFindNext(NULL, &acd);
    
    // 3、创建音频组件实例。
    OSStatus status = AudioComponentInstanceNew(component, &_audioCaptureInstance);
    if (status != noErr) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:status userInfo:nil];
        return;
    }
```
AudioUnitInitialize(...)：初始化一个 AudioUnit (AudioUnit 就是一种 AudioComponentInstance )。如果初始化成功，说明 input/output 的格式是可支持的，并且处于可以开始渲染的状态。
```
 status = AudioUnitInitialize(_audioCaptureInstance);
```
AudioUnitSetProperty(...)：设置 AudioUnit 的属性。
```
status = AudioUnitSetProperty(_audioCaptureInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd, sizeof(asbd));
status = AudioUnitSetProperty(_audioCaptureInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &cb, sizeof(cb));
```
AudioOutputUnitStart(...)：启动一个 I/O AudioUnit，同时会启动与之连接的 AudioUnit Processing Graph。
AudioOutputUnitStop(...)：关闭一个 I/O AudioUnit，同时会关闭与之连接的 AudioUnit Processing Graph。
```
- (void)startRunning {
    OSStatus startStatus = AudioOutputUnitStart(weakSelf.audioCaptureInstance);
}

- (void)stopRunning {
    OSStatus stopStatus = AudioOutputUnitStop(weakSelf.audioCaptureInstance);
}
```
##### 2、编解码流程Api说明
AudioStreamBasicDescription：用于描述音频流数据格式信息，比如采样位深、声道数、采样率、每帧字节数、每包帧数、每包字节数、格式标识等。
```
// 1、设置音频编码器输出参数。其中一些参数与输入的音频数据参数一致。
    AudioStreamBasicDescription outputFormat = {0};
    outputFormat.mSampleRate = inputFormat.mSampleRate; // 输出采样率与输入一致。
    outputFormat.mFormatID = kAudioFormatMPEG4AAC; // AAC 编码格式。常用的 AAC 编码格式：kAudioFormatMPEG4AAC、kAudioFormatMPEG4AAC_HE_V2。
    outputFormat.mFormatFlags = kMPEG4Object_AAC_Main; // AAC 编码 Profile。注意要设置这个，因为这个枚举值是从 1 开始的，不设置确定值很容易出问题。
    outputFormat.mChannelsPerFrame = (UInt32) inputFormat.mChannelsPerFrame; // 输出声道数与输入一致。
    outputFormat.mFramesPerPacket = 1024; // 每个包的帧数。AAC 固定是 1024，这个是由 AAC 编码规范规定的。对于未压缩数据设置为 1。
    outputFormat.mBytesPerPacket = 0; // 每个包的大小。动态大小设置为 0。
    outputFormat.mBytesPerFrame = 0; // 每帧的大小。压缩格式设置为 0。
    outputFormat.mBitsPerChannel = 0; // 压缩格式设置为 0。
```
CMSampleBufferGetFormatDescription(...)：返回 CMSampleBuffer 中的采样数据对应的 CMFormatDescription。
CMAudioFormatDescriptionGetStreamBasicDescription(...)：返回一个指向 CMFormatDescription（通常应该是一个 CMAudioFormatDescription） 中的 AudioStreamBasicDescription 的指针。如果是非音频格式，就返回 NULL。
```
// 1、从输入数据中获取音频格式信息。
    CMAudioFormatDescriptionRef audioFormatRef = CMSampleBufferGetFormatDescription(buffer);
    if (!audioFormatRef) {
        return;
    }
    // 获取音频参数信息，AudioStreamBasicDescription 包含了音频的数据格式、声道数、采样位深、采样率等参数。
    AudioStreamBasicDescription audioFormat = *CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatRef);
```

AudioConverterRef：音频编解码。支持 LPCM 各种格式转换，以及 LPCM 与编码格式（如 AAC）的转换。
AudioConverterNew(...)：根据指定的输入和输出音频格式创建对应的转换器（编解码器）实例。
```
typedef struct OpaqueAudioConverter *   AudioConverterRef;
@property (nonatomic, assign) AudioConverterRef audioEncoderInstance; // 音频编码器实例。
OSStatus result = AudioConverterNew(&inputFormat, &outputFormat, &_audioEncoderInstance);
```
AudioBufferList[48]：一组 AudioBuffer,编解码后的数据是存在 AudioBuffer中的。
AudioConverterFillComplexBuffer(...)：转换（编码）回调函数提供的音频数据，支持不交错和包格式。大部分情况下都建议用这个接口，除非是要将音频数据从一种 LPCM 格式转换为另外一种。
AudioConverterComplexInputDataProc：为 AudioConverterFillComplexBuffer(...) 接口提供输入数据的回调。
```
//  2、创建编码输出缓冲区 AudioBufferList 接收编码后的数据。
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = inBuffer.mNumberChannels;
    outBufferList.mBuffers[0].mDataByteSize = inBuffer.mDataByteSize; // 设置编码缓冲区大小。
    outBufferList.mBuffers[0].mData = _aacBuffer; // 绑定缓冲区空间。
    
    // 3、编码。
    UInt32 outputDataPacketSize = 1; // 每次编码 1 个包。1 个包有 1024 个帧，这个对应创建编码器实例时设置的 mFramesPerPacket。
    // 需要在回调方法 inputDataProcess 中将待编码的数据拷贝到编码器的缓冲区的对应位置。这里把我们自己创建的待编码缓冲区 AudioBufferList 作为 inInputDataProcUserData 传入，在回调方法中直接拷贝它。
    OSStatus status = AudioConverterFillComplexBuffer(_audioEncoderInstance, inputDataProcess, &inBufferList, &outputDataPacketSize, &outBufferList, NULL);
// 回调函数
static OSStatus inputDataProcess(AudioConverterRef inConverter,
                                 UInt32 *ioNumberDataPackets,
                                 AudioBufferList *ioData,
                                 AudioStreamPacketDescription **outDataPacketDescription,
                                 void *inUserData) {
    // 将待编码的数据拷贝到编码器的缓冲区的对应位置进行编码。
    AudioBufferList bufferList = *(AudioBufferList *) inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = bufferList.mBuffers[0].mDataByteSize;
    
    return noErr;
}
```

CMSampleBuffer：系统用来在音视频处理的 pipeline 中使用和传递媒体采样数据的核心数据结构。你可以认为它是 iOS 音视频处理 pipeline 中的流通货币，摄像头采集的视频数据接口、麦克风采集的音频数据接口、编码和解码数据接口、读取和存储视频接口、视频渲染接口等等，都以它作为参数。通常，CMSampleBuffer 中要么包含一个或多个媒体采样的 CMBlockBuffer，要么包含一个 CVImageBuffer。
CMBlockBuffer：一个或多个媒体采样的的裸数据。其中可以封装：音频采集后、编码后、解码后的数据（如：PCM 数据、AAC 数据）；视频编码后的数据（如：H.264 数据）。
CMSampleBufferCreateReady(...)：基于媒体数据创建一个 CMSampleBuffer。
CMBlockBufferCreateWithMemoryBlock(...)：基于内存数据创建一个 CMBlockBuffer。
```
    size_t aacEncoderSize = outBufferList.mBuffers[0].mDataByteSize;
    char *blockBufferDataPoter = malloc(aacEncoderSize);
    memcpy(blockBufferDataPoter, _aacBuffer, aacEncoderSize);
    // 编码数据封装到 CMBlockBuffer 中。
    CMBlockBufferRef blockBuffer = NULL;
    status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                 blockBufferDataPoter,
                                                 aacEncoderSize,
                                                 NULL,
                                                 NULL,
                                                 0,
                                                 aacEncoderSize,
                                                 0,
                                                 &blockBuffer);
    if (status != kCMBlockBufferNoErr) {
        return;
    }
    // 编码数据 CMBlockBuffer 再封装到 CMSampleBuffer 中。
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = {aacEncoderSize};
    status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                       blockBuffer,
                                       _aacFormat,
                                       1,
                                       1,
                                       &timing,
                                       1,
                                       sampleSizeArray,
                                       &sampleBuffer);
```
#####简书地址：https://www.jianshu.com/p/0d72f77504e5
