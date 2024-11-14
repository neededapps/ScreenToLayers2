
#import "PSDUtilities.h"
#import "PSDStream.h"
#import "NSData+PSD.h"

#pragma mark - PSD utilities

typedef uint8_t PSDPixelCo;

typedef struct _PSDPixel {
#ifdef __LITTLE_ENDIAN__
    PSDPixelCo b;
    PSDPixelCo g;
    PSDPixelCo r;
    PSDPixelCo a;
#else
    PSDPixelCo a;
    PSDPixelCo r;
    PSDPixelCo g;
    PSDPixelCo b;
#endif
} PSDPixel;

#pragma mark - Quartz utilities

CGPoint PSDCGPointAdd(CGPoint p1, CGPoint p2)  {
    return CGPointMake(p1.x + p2.x, p1.x + p2.x);
}

CGPoint PSDCGPointSub(CGPoint p1, CGPoint p2) {
    return CGPointMake(p1.x - p2.x, p1.y - p2.y);
}

CGPoint PSDCGPointMult(CGPoint point, CGFloat value) {
    return CGPointMake(point.x * value, point.y * value);
}

CGSize PSDCGSizeMult(CGSize size, CGFloat value) {
    return CGSizeMake(size.width * value, size.height * value);
}

CGRect PSDCGRectMult(CGRect rect, CGFloat value) {
    CGRect result = rect;
    result.origin.x *= value;
    result.origin.y *= value;
    result.size.width *= value;
    result.size.height *= value;
    return result;
}

CGRect PSDCGRectFloor(CGRect rect) {
    CGRect result;
    result.origin.x = floorf(rect.origin.x);
    result.origin.y = floorf(rect.origin.y);
    result.size.width = floorf(rect.size.width);
    result.size.height = floorf(rect.size.height);
    return result;
}

CGRect PSDCGRectFromOS(CGPoint origin, CGSize size) {
    return (CGRect){origin, size};
}

#pragma mark - CGImage utilities

NSData *PSDImageGetDataInRegion(CGImageRef imageRef, CGRect region) {
    int width = region.size.width;
    int height = region.size.height;
    int bitmapBytesPerRow = (width * 4);
    int bitmapByteCount = (bitmapBytesPerRow * height);
    
    CGColorSpaceRef colorspace = CGImageGetColorSpace(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    bitmapInfo = (CGBitmapInfo)(kCGImageAlphaPremultipliedLast
                                | kCGBitmapByteOrder32Little);
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 width,
                                                 height,
                                                 8,
                                                 bitmapBytesPerRow,
                                                 colorspace,
                                                 bitmapInfo);
    
    if (context == NULL) return nil;
    
    CGRect drawRegion;
    drawRegion.origin = CGPointZero;
    drawRegion.size.width = width;
    drawRegion.size.height = height;
    
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextTranslateCTM(context,
                          - region.origin.x + (drawRegion.size.width  - region.size.width),
                          - region.origin.y - (drawRegion.size.height - region.size.height));
    CGContextDrawImage(context, drawRegion, imageRef);
    
    void *bitmapData = CGBitmapContextGetData(context);
    NSData *data = [NSData dataWithBytes:bitmapData length:bitmapByteCount];
    CGContextRelease(context);
    return data;
}

NSData *PSDImageGetData(CGImageRef imageRef) {
    CGRect region = CGRectZero;
    region.size.width = CGImageGetWidth(imageRef);
    region.size.height = CGImageGetHeight(imageRef);
    return PSDImageGetDataInRegion(imageRef, region);
}

#pragma mark - Encoding utilities

#define MIN_RUN     3                           // minimum run length to encode
#define MAX_RUN     128                         // maximum run length to encode
#define MAX_COPY    128                         // maximum characters to copy

#define MAX_READ    (MAX_COPY + MIN_RUN - 1)    // maximum that can be read before copy block is written

static void appendUncompressedRun(NSMutableData *data, unsigned char* start, size_t count) {
    assert(count > 0 && count <= MAX_COPY);
    
    SInt8 encodedLen = count - 1;
    [data appendBytes:&encodedLen length:1];
    [data appendBytes:start length:count];
}

static void appendCompressedRun(NSMutableData *data, unsigned char value, size_t count) {
    assert(count > 0 && count <= MAX_RUN);
    
    SInt8 encodedLen = ((int)(1 - (int)(count)));
    [data appendBytes:&encodedLen length:sizeof(SInt8)];
    [data appendBytes:&value length:sizeof(UInt8)];
}

static NSData * PSDEncodePackBitsPart(char* bytesIn, size_t bytesLength, off_t skip) {
    NSMutableData *data = [NSMutableData data];
    
    BOOL atEnd = NO;
    
    int count = 0; // number of characters in a run
    unsigned char charBuf[MAX_READ]; // buffer of already read characters
    
    // prime the read loop
    off_t bytesOffset = 0;
    unsigned char currChar = bytesIn[bytesOffset];
    bytesOffset += skip;
    
    // read input until there’s nothing left
    while (!atEnd) {
        charBuf[count] = (unsigned char) currChar;
        count++;
        
        if (count >= MIN_RUN) {
            int i;
            
            // check for run charBuf[count - 1] .. charBuf[count - MIN_RUN]
            for (i = 2; i <= MIN_RUN; i++) {
                if (currChar != charBuf[count - i]) {
                    // no run
                    i = 0;
                    break;
                }
            }
            
            if (i != 0) {
                // we have a run write out buffer before run
                int nextChar;
                
                if (count > MIN_RUN) {
                    // block size – 1 followed by contents
                    appendUncompressedRun(data, &charBuf[0], count - MIN_RUN);
                }
                
                // determine run length (MIN_RUN so far)
                count = MIN_RUN;
                while (true) {
                    if ((size_t)bytesOffset < bytesLength) {
                        nextChar = bytesIn[bytesOffset];
                        bytesOffset += skip;
                    } else {
                        atEnd = YES;
                        nextChar = EOF;
                    }
                    
                    if (atEnd || nextChar != currChar) {
                        break;
                    }
                    
                    count++;
                    if (count == MAX_RUN) {
                        // run is at max length
                        break;
                    }
                }
                
                // write out encoded run length and run symbol
                appendCompressedRun(data, currChar, count);
                
                if (!atEnd && count != MAX_RUN) {
                    // make run breaker start of next buffer
                    charBuf[0] = nextChar;
                    count = 1;
                } else {
                    // file or max run ends in a run
                    count = 0;
                }
            }
        }
        
        if (count == MAX_READ) {
            int i;
            
            // write out buffer
            appendUncompressedRun(data, &charBuf[0], MAX_COPY);
            
            // start a new buffer
            count = MAX_READ - MAX_COPY;
            
            // copy excess to front of buffer
            for (i = 0; i < count; i++) {
                charBuf[i] = charBuf[MAX_COPY + i];
            }
        }
        
        if ((size_t)bytesOffset < bytesLength) {
            currChar = bytesIn[bytesOffset];
        } else {
            atEnd = YES;
        }
        
        bytesOffset += skip;
    }
    
    // write out last buffer
    if (0 != count) {
        if (count <= MAX_COPY) {
            // write out entire copy buffer
            appendUncompressedRun(data, &charBuf[0], count);
        } else {
            // we read more than the maximum for a single copy buffer
            appendUncompressedRun(data, &charBuf[0], MAX_COPY);
            
            // write out remainder
            count -= MAX_COPY;
            appendUncompressedRun(data, &charBuf[MAX_COPY], count);
        }
    }
    
    return data;
}

NSData *PSDEncodedPackBits(char* src, size_t w, size_t h, size_t bytesLength) {
    NSMutableArray *lineData = [NSMutableArray arrayWithCapacity:h];
    for (size_t i = 0 ; i < h ; i++) {
        NSData *data = PSDEncodePackBitsPart(src + i * w, bytesLength, 1);
        [lineData addObject:data];
    }
    
    PSDStream *outputStream = [PSDStream streamForWritingToMemory];
    [outputStream writeInt16:1]; // The encoding
    
    NSInteger totalLen = 0;
    for (NSData *line in lineData) {
        NSInteger len = [line length];
        totalLen += len;
        [outputStream writeInt16:len];
    }
    
    for (NSData *line in lineData) {
        [outputStream writeData:line];
    }
    
    [outputStream close];
    return [outputStream outputData];
}

NSArray *PSDPackedImageData(NSData *data, CGSize size) {
    NSMutableArray *layerChannels = [NSMutableArray array];
    int width = (int)size.width;
    int height = (int)size.height;
    int imageRowBytes = width * 4;
    
    for (int channel = 0; channel < 4; channel++) {
        NSMutableData *byteCounts, *scanlines;
        byteCounts = [NSMutableData dataWithCapacity:height * 4 * 2];
        scanlines = [NSMutableData data];
        
        for (int row = 0; row < height; row++) {
            @autoreleasepool {
                int start = row * imageRowBytes + channel;
                NSRange packRange = NSMakeRange(start, imageRowBytes);
                NSData *packed = [data psd_packedBitsForRange:packRange skip:4];
                [scanlines appendData:packed];
                [byteCounts appendValue:packed.length length:2];
            }
        }
        
        NSMutableData *channelData = [[NSMutableData alloc] init];
        [channelData appendValue:1 length:2];     // write compression format
        [channelData appendData:byteCounts];      // write channel byte counts
        [channelData appendData:scanlines];       // write channel scanlines
        [layerChannels addObject:channelData];
    }
    return layerChannels;
}

NSData *PSDPackedPreviewImageData(NSData *data, CGSize size) {
    int capacity = size.height * 4 * 2;
    NSMutableData *byteCounts = [NSMutableData dataWithCapacity:capacity];
    NSMutableData *scanlines = [NSMutableData data];
    
    int imageRowBytes = size.width * 4;
    int argbCount = 4, argb[] = {3, 2, 1, 0};
    for (int channel = 0; channel < argbCount; channel++) {
        for (int row = 0; row < size.height; row++) {
            @autoreleasepool {
                int start = row * imageRowBytes + argb[channel];
                NSRange packRange = NSMakeRange(start, imageRowBytes);
                NSData *packed = [data psd_packedBitsForRange:packRange skip:4];
                [byteCounts appendValue:packed.length length:2];
                [scanlines appendData:packed];
            }
        }
    }
    
    NSMutableData *result = [NSMutableData data];
    [result appendData:byteCounts];
    [result appendData:scanlines];
    return result;
}
