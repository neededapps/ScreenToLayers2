
@import Foundation;

@interface PSDStream : NSObject

#pragma mark Initializers

+ (id)streamForReadingURL:(NSURL*)url;
+ (id)streamForReadingData:(NSData*)data;
+ (id)streamForWritingToURL:(NSURL*)url;
+ (id)streamForWritingToMemory;

#pragma mark Manage stream

- (void)close;
- (NSData*)outputData;

#pragma mark Read data

- (uint8_t)readInt8;
- (uint16_t)readInt16;
- (uint32_t)readInt32;
- (int32_t)readSInt32;
- (uint64_t)readInt64;
- (double)readDouble64;
- (NSInteger)readChars:(char *)buffer maxLength:(NSUInteger)len;
- (NSString*)readPSDString;
- (NSString*)readPSDStringOfLength:(uint32_t)size;
- (NSString*)readPSDStringOrGetFourByteID:(uint32_t*)outId;
- (NSString*)readPascalString;
- (NSString*)readPSDString16;
- (NSMutableData*)readDataOfLength:(NSUInteger)len;
- (NSData*)readToEOF;

- (BOOL)hasLengthToRead:(NSUInteger)len;
- (void)skipLength:(NSUInteger)len;
- (long)location;
- (void)seekToLocation:(long)newLocation;

#pragma mark Write data

- (void)writeInt64:(uint64_t)value;
- (void)writeInt32:(uint32_t)value;
- (void)writeInt16:(uint16_t)value;
- (void)writeSInt16:(int16_t)value;
- (void)writeInt8:(uint8_t)value;
- (void)writeData:(NSData*)data;
- (void)writeChars:(char*)chars length:(size_t)length;
- (void)writeDataWithLengthHeader:(NSData*)data;

- (void)writePackedData:(NSArray *)data;
- (void)writePascalString:(NSString*)string withPadding:(int)p;
- (void)writeUnicodeName:(NSString *)name;

@end
