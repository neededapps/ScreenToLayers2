
#import "PSDImageLayer.h"
#import "PSDStream.h"
#import "PSDUtilities.h"

#pragma mark - PSDImageLayer private

@interface PSDImageLayer ()
{
    NSArray *_packedImageData;
}

@end

#pragma mark - PSDImageLayer implementation

@implementation PSDImageLayer

#pragma mark Initializers

- (void)dealloc
{
    _packedImageData = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark PSD writing

- (void)generatePackedDataWithDocumentSize:(CGSize)size
{
    _packedImageData = PSDPackedImageData(self.imageData, self.rect.size);
}

- (void)clearPackedData
{
    _packedImageData = nil;
}

- (void)writeImageDataToStream:(PSDStream *)stream documentSize:(CGSize)size
{
    [stream writeData:_packedImageData[0]];
    [stream writeData:_packedImageData[3]];
    [stream writeData:_packedImageData[2]];
    [stream writeData:_packedImageData[1]];
}

- (void)writeLayerInfoToStream:(PSDStream *)stream documentSize:(CGSize)size
{
    [stream writeInt32:(int)ceilf(CGRectGetMinY(self.rect))];  // top
    [stream writeInt32:(int)ceilf(CGRectGetMinX(self.rect))];  // left
    [stream writeInt32:(int)ceilf(CGRectGetMaxY(self.rect))];  // bottom
    [stream writeInt32:(int)ceilf(CGRectGetMaxX(self.rect))];  // right
    [stream writeInt16:4];                                     // channels
    
    [stream writeSInt16:-1];
    [stream writeInt32:(uint32_t)([_packedImageData[0] length])];
    [stream writeSInt16:0];
    [stream writeInt32:(uint32_t)([_packedImageData[3] length])];
    [stream writeSInt16:1];
    [stream writeInt32:(uint32_t)([_packedImageData[2] length])];
    [stream writeSInt16:2];
    [stream writeInt32:(uint32_t)([_packedImageData[1] length])];
    
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
    [extraDataStream writePascalString:self.name withPadding:4];
    [extraDataStream writeUnicodeName: self.name];
    [stream writeDataWithLengthHeader:[extraDataStream outputData]];
}

@end
