
#import "PSDGroupLayer.h"
#import "PSDStream.h"
#import "PSDUtilities.h"

#pragma mark - PSDGroupLayer private

@interface PSDGroupLayer () {
    NSArray *_packedImageData;
}

@end

#pragma mark - PSDGroupLayer implementation

@implementation PSDGroupLayer

#pragma mark Initializers

- (void)dealloc
{
    _packedImageData = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Nothing to setup
    }
    return self;
}

#pragma mark PSD writing

- (void)generatePackedDataWithDocumentSize:(CGSize)size
{
    int zero[] = {0};
    _packedImageData = [NSArray arrayWithObjects:
        [NSData dataWithBytes:zero length:4],
        [NSData dataWithBytes:zero length:4],
        [NSData dataWithBytes:zero length:4],
        [NSData dataWithBytes:zero length:4],
        nil];
}

- (void)clearPackedData
{
    _packedImageData = nil;
}

- (void)writeImageDataToStream:(PSDStream *)stream documentSize:(CGSize)size
{
    [stream writeInt16:0]; // -1
    [stream writeInt16:0]; // 0
    [stream writeInt16:0]; // 1
    [stream writeInt16:0]; // 2
}

- (void)writeLayerInfoToStream:(PSDStream *)stream documentSize:(CGSize)size
{
    [stream writeInt32:0]; // top
    [stream writeInt32:0]; // left
    [stream writeInt32:0]; // bottom
    [stream writeInt32:0]; // right
    [stream writeInt16:4]; // channels
    
    [stream writeSInt16:-1]; // id
    [stream writeInt32:2];   // length
    [stream writeSInt16:0];  // id
    [stream writeInt32:2];   // length
    [stream writeSInt16:1];  // id
    [stream writeInt32:2];   // length
    [stream writeSInt16:2];  // id
    [stream writeInt32:2];   // length
    
    [stream writeInt32:'8BIM'];
    [stream writeInt32:'norm'];
    [stream writeInt8:(int)floorf(self.opacity * 255.0f)]; // opacity
    [stream writeInt8:0]; // Clipping: 0 = base, 1 = non–base
    [stream writeInt8:1]; // visible, preserve transparency, etc.
    [stream writeInt8:0]; // filler.
}

- (void)writeExtraInfoToStream:(PSDStream *)stream documentSize:(CGSize)size
{
    PSDStream *extraDataStream = [PSDStream streamForWritingToMemory];
    [extraDataStream writeInt32:0]; // mask
    [extraDataStream writeInt32:0]; // Layer blending ranges

    NSString *writtenName = self.isHead ? @"</Layer group>" : self.name;
    [extraDataStream writePascalString:writtenName withPadding:4];
    
    [extraDataStream writeInt32:'8BIM'];
    [extraDataStream writeInt32:'lsct'];
    if (self.isHead) {
        [extraDataStream writeInt32:4]; // Section divider length
        [extraDataStream writeInt32:3]; // Group type (layer hidden)
    } else {
        [extraDataStream writeInt32:12]; // Section divider length
        [extraDataStream writeInt32:((self.isOpened) ? 1 : 2)];
        [extraDataStream writeInt32:'8BIM'];
        [extraDataStream writeInt32:'pass'];
    }
    
    [extraDataStream writeUnicodeName: writtenName];
    [stream writeDataWithLengthHeader:[extraDataStream outputData]];
}

@end
