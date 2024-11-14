
#import "PSDStream.h"

#pragma mark - PSDStream private

@interface PSDStream () {
    NSOutputStream *_outputStream;
    NSData *_inputDataStream;
    long _location;
}

- (id)initWithInputURL:(NSURL*)fileURL;
- (id)initWithOutputURL:(NSURL*)fileURL;
- (id)initWithOutputToMemory;

@end

#pragma mark - PSDWriter implementation

@implementation PSDStream

#pragma mark Initializers

+ (id)streamForReadingURL:(NSURL*)url
{
    PSDStream *stream = [[PSDStream alloc] initWithInputURL:url];
    return stream;
}

+ (id)streamForWritingToURL:(NSURL*)url
{
    PSDStream *stream = [[PSDStream alloc] initWithOutputURL:url];
    return stream;
}


+ (id)streamForWritingToMemory
{
    PSDStream *stream = [[PSDStream alloc] initWithOutputToMemory];
    return stream;
}

+ (id)streamForReadingData:(NSData*)data
{
    PSDStream *stream = [[PSDStream alloc] initWithData:data];
    return stream;
}

- (id)initWithData:(NSData*)data
{
    self = [super init];
    if (self != nil) {
        _inputDataStream = data;
    }
    return self;
}

- (id)initWithInputURL:(NSURL*)fileURL
{
	self = [super init];
	if (self != nil) {
        NSError *err = nil;
        _inputDataStream = [NSData dataWithContentsOfURL:fileURL
                                                 options:NSDataReadingMapped
                                                   error:&err];
        if (!_inputDataStream && err) {
            NSLog(@"err: '%@'", err);
            return nil;
        }
	}
	return self;
}

- (id)initWithOutputURL:(NSURL*)fileURL
{
	self = [super init];
	if (self != nil) {
		_outputStream = [NSOutputStream outputStreamWithURL:fileURL
                                                     append:NO];
        [_outputStream open];
	}
	return self;
}

- (id)initWithOutputToMemory
{
	self = [super init];
	if (self != nil) {
		_outputStream = [NSOutputStream outputStreamToMemory];
        [_outputStream open];
	}
	return self;
}

#pragma mark Manage stream

- (void)close
{
    if (_outputStream) {
        [_outputStream close];
    }
}

#pragma mark Read data

- (BOOL)hasLengthToRead:(NSUInteger)len
{
    if (_location + len > [_inputDataStream length]) {
        return NO;
    }
    return YES;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
    uint8_t *foo = (uint8_t *)[_inputDataStream bytes];
    foo += _location;
    
    if (_location + len > [_inputDataStream length]) {
        NSString *s = [NSString stringWithFormat:
                       @"trying to read to %lu bytes of %lu",
                       _location + len, (unsigned long)[_inputDataStream length]];
        NSLog(@"%@", s);
        [NSException raise:@"PSD Buffer Overrun" format:@"%@", s];
        return -1;
    }
    
    memcpy(buffer, foo, len);
    _location += len;
    return len;
}

- (uint8_t)readInt8
{
    uint8_t value = 0;
    [self read:&value maxLength:1];
    return value;
}

- (uint16_t)readInt16
{
    uint8_t buffer[2];
    uint16_t value = 0;
    
    if ([self read:buffer maxLength:2] == 2) {
        value  = buffer[0] << 8;
        value |= buffer[1];
    }
    return value;
}

- (uint32_t)readInt32
{
    uint8_t buffer[4];
    uint32_t value = -1;
    
    if ([self read:buffer maxLength:4] == 4) {
        value  = buffer[0] << 24;
        value |= buffer[1] << 16;
        value |= buffer[2] << 8;
        value |= buffer[3];
    }
    return value;
}

- (int32_t)readSInt32
{
    uint8_t buffer[4];
    int32_t value = -1;
    
    if ([self read:buffer maxLength:4] == 4) {
        value  = ((uint32_t)buffer[0]) << 24;
        value |= buffer[1] << 16;
        value |= buffer[2] << 8;
        value |= buffer[3];
    }
    return value;
}

- (double)readDouble64
{
    CFSwappedFloat64 sf;
    [self read:(uint8_t*)&sf.v maxLength:8];
    double f = CFConvertDoubleSwappedToHost(sf);
    return f;
}

- (uint64_t)readInt64
{
    uint64_t value = 0;
    [self read:(uint8_t*)&value maxLength:8];
#ifdef __LITTLE_ENDIAN__
    value = CFSwapInt64(value);
#endif
    return value;
}

- (NSInteger)readChars:(char *)buffer maxLength:(NSUInteger)len
{
    return [self read:(uint8_t*)buffer maxLength:len];
}

- (NSString*)readPSDString16
{
    int32_t size = [self readInt32];
    if (size <= 0) {
        return @"";
    }
    
    unichar *c = malloc(sizeof(unichar) * (size + 1));
    for (int32_t i = 0; i < size; i++) {
        c[i] = [self readInt16];
        if (c[i] == 0) {
            size = i;
            break;
        }
    }
    
    c[size + 1] = 0;
    NSString *s = [[NSString alloc] initWithCharacters:c length:size];
    free(c);
    return s;
}

- (NSString*)readPSDStringOrGetFourByteID:(uint32_t*)outId
{
    int32_t size = [self readInt32];
    if (size <= 0) {
        *outId = [self readInt32];
        return nil;
    }
    
    char *c = malloc(sizeof(char) * (size + 1));
    [self readChars:c maxLength:size];
    c[size] = 0;
    
    NSString *s = [NSString stringWithFormat:@"%s", c];
    free(c);
    return s;
}

- (NSString*)readPSDString
{
    uint32_t size = [self readInt32];
    if (size == 0) {
        size = 4;
    }
    return [self readPSDStringOfLength:size];
}

- (NSString*)readPSDStringOfLength:(uint32_t)size
{
    char *c = malloc(sizeof(char) * (size + 1));
    NSInteger read = [self readChars:c maxLength:size];
    c[size] = 0;
    
    (void)read;
    NSString *s = [NSString stringWithFormat:@"%s", c];
    free(c);
    return s;
}

- (NSString*)readPascalString
{
    uint8_t size = [self readInt8];
    if((size & 0x01) == 0) {
        size ++;
    }
    
    char *c = malloc(sizeof(char) * (size + 1));
    [self readChars:c maxLength:size];
    c[size] = 0;
    
    NSString *s = [NSString stringWithFormat:@"%s", c];
    free(c);
    return s;
}

- (void)skipLength:(NSUInteger)len
{
    _location += len;
}

- (long)location
{
    return _location;
}

- (void)seekToLocation:(long)newLocation
{
    _location = newLocation;
}

- (NSMutableData*)readDataOfLength:(NSUInteger)len
{
    if (len == 0) {
        return [NSMutableData data];
    }
    
    NSUInteger leftToRead = len;
    NSMutableData *data = [NSMutableData dataWithLength:len];
    uint8_t *p = [data mutableBytes];
    
    [self read:p maxLength:leftToRead];
    return data;
}

- (NSData*)readToEOF
{
    NSMutableData *data = [NSMutableData data];
    int buffSize = 1024;
    NSInteger read;
    char *c = malloc(sizeof(char) * buffSize);
    
    while ((read = [self readChars:c maxLength:buffSize]) > 0) {
        [data appendBytes:c length:read];
    }
    
    free(c);
    return data;
}

#pragma mark Write data

- (void)writeInt64:(uint64_t)value
{
    uint64_t writeV = CFSwapInt64HostToBig(value);
    [_outputStream write:(const uint8_t *)&writeV maxLength:8];
    _location += 8;
}

- (void)writeInt32:(uint32_t)value
{
    uint32_t writeV = CFSwapInt32HostToBig(value);
    [_outputStream write:(const uint8_t *)&writeV maxLength:4];
    _location += 4;
}

- (void)writeInt16:(uint16_t)value
{
    uint32_t writeV = CFSwapInt16HostToBig(value);
    [_outputStream write:(const uint8_t *)&writeV maxLength:2];
    _location += 2;
}

- (void)writeSInt16:(int16_t)value
{
    uint32_t writeV = CFSwapInt16HostToBig(value);
    [_outputStream write:(const uint8_t *)&writeV maxLength:2];
    _location += 2;
}

- (void)writeInt8:(uint8_t)value
{
    [_outputStream write:(const uint8_t *)&value maxLength:1];
    _location += 1;
}

- (void)writeDataWithLengthHeader:(NSData*)data
{
    [self writeInt32:(uint32_t)[data length]];
    if ([data length] == 0) {
        return;
    }
    
    NSInteger wrote = [_outputStream write:[data bytes] maxLength:[data length]];
    if (wrote != (NSInteger)[data length]) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(@"didn't write enough data!");
    }
    _location += [data length];
}

- (void)writeData:(NSData*)data
{
    NSInteger wrote = [_outputStream write:[data bytes] maxLength:[data length]];
    if (wrote != (NSInteger)[data length]) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(@"didn't write enough data!");
    }
    _location += [data length];
}

- (void)writeChars:(char*)chars length:(size_t)length
{
    if (!length) {
        return;
    }
    
    NSInteger wrote = [_outputStream write:(const uint8_t *)chars maxLength:length];
    if (wrote != (NSInteger)length) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(@"didn't write enough data!");
    }
    _location += length;
}

- (void)writePackedData:(NSArray *)data
{
    [self writeData:data[0]];
    [self writeData:data[1]];
    [self writeData:data[2]];
    [self writeData:data[3]];
}

- (void)writeValue:(long)value length:(int)length
{
    Byte bytes[8];
    double divider = 1;
    for (int ii = 0; ii < length; ii++){
        bytes[length-ii-1] = (long)(value / divider) % 256;
        divider *= 256;
    }
    [self writeData:[NSData dataWithBytes:&bytes length:length]];
}

- (void)writePascalString:(NSString*)string withPadding:(int)p
{
    if (![string canBeConvertedToEncoding:NSMacOSRomanStringEncoding]) {
        NSData *what = [string dataUsingEncoding:NSMacOSRomanStringEncoding
                            allowLossyConversion:YES];
        
        NSString *foo = [[NSString alloc] initWithData:what
                                              encoding:NSMacOSRomanStringEncoding];
        if (!foo) {
            NSLog(@"Could not convert %@ to NSMacOSRomanStringEncoding", string);
        }
        string = foo;
    }
    
    CFIndex len = CFStringGetLength((CFStringRef)string) + 1;
	unsigned char *buffer = malloc(sizeof(unsigned char) * len);
    BOOL result = CFStringGetPascalString((CFStringRef)string,
                                          buffer, len,
                                          kCFStringEncodingMacRoman);
	if (result) {
        [_outputStream write:(const uint8_t *)buffer maxLength:len];
        _location += len;
        
        while (len % p) {
            [self writeInt8:0];
            len++;
        }
    } else {
        NSLog(@"Could not write layer name! %@", string);
        if ([string length] > 128) {
            NSString *trimedString = [NSString stringWithFormat:
                                      @"%@...",
                                      [string substringToIndex:125]];
            [self writePascalString:trimedString withPadding:p];
        } else if (![string isEqualToString:@"Untitled"]) {
            [self writePascalString:@"Untitled" withPadding:p];
        }
    }
    
    free(buffer);
}

- (void)writeUnicodeName:(NSString *)name
{
    NSMutableData *data = [NSMutableData data];
    [self writeInt32:'8BIM'];
    [self writeInt32:'luni']; // Unicode layer name (Photoshop 5.0)
    
    NSRange r = NSMakeRange(0, name.length);
    [self writeValue:(r.length * 2) + 4 length:4]; // length of the next bit of data
    [self writeValue:r.length length:4];           // length of the unicode string data
    
    int bufferSize = sizeof(unichar) * ((int)[name length] + 1);
    unichar *buffer = malloc(bufferSize);
    [name getCharacters:buffer range:r];
    buffer[([name length])] = 0;
    for (NSUInteger i = 0; i < name.length; i++) {
        [self writeValue:buffer[i] length:2];
    }
    [self writeData:data];
    free(buffer);
}

- (NSData*)outputData
{
    return [_outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
}

@end
