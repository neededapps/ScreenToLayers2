
#import "PSDWriter.h"
#import "PSDStream.h"
#import "PSDImageLayer.h"
#import "PSDGroupLayer.h"
#import "PSDUtilities.h"

#pragma mark PSDWriter private

@interface PSDWriter ()

@property (strong) NSMutableArray *layers;
@property (strong) NSMutableArray *groups;
@property (strong) NSData *previewData;
@property (strong) NSData *packedPreviewData;
@property (assign) BOOL allowEmptyDocument;

@end

#pragma mark PSDWriter implementation

@implementation PSDWriter

- (instancetype)init
{
    return [self initWithSize:CGSizeMake(512.0, 512.0)];
}

- (instancetype)initWithSize:(CGSize)size
{
    self = [super init];
    if (self){
        _includesICC = NO;
        _size = size;
        _layers = [[NSMutableArray alloc] init];
        _groups = [[NSMutableArray alloc] init];
        _maxConcurentOperationsCount = 8;
        _allowEmptyDocument = YES;
    }
    return self;
}
    
#pragma mark Create layers
    
- (nullable PSDLayer *)createLayerWithImage:(CGImageRef)image
                                       name:(NSString *)name
                                     offset:(CGPoint)offset
{
    CGFloat width = CGImageGetWidth(image);
    CGFloat height = CGImageGetHeight(image);
    if (width == 0.0 || height == 0.0) {
        return nil;
    }
    
    CGRect imageRegion = CGRectMake(0, 0, width ,height);
    CGRect screenRegion = imageRegion;
    screenRegion.origin = offset;
    
    if (CGRectGetMaxX(screenRegion) > _size.width) {
        imageRegion.size.width = _size.width - screenRegion.origin.x;
        screenRegion.size.width = imageRegion.size.width;
    }
    if (CGRectGetMaxY(screenRegion) > _size.height) {
        imageRegion.size.height = _size.height - screenRegion.origin.y;
        screenRegion.size.height = imageRegion.size.height;
    }
    if (CGRectGetMinX(screenRegion) < 0) {
        imageRegion.origin.x = fabs(screenRegion.origin.x);
        screenRegion.origin.x = 0;
        screenRegion.size.width = imageRegion.size.width - imageRegion.origin.x;
        imageRegion.size.width = screenRegion.size.width;
    }
    if (CGRectGetMinY(screenRegion) < 0) {
        imageRegion.origin.y = fabs(screenRegion.origin.y);
        screenRegion.origin.y = 0;
    }
    
    if (imageRegion.size.width <= 0 || imageRegion.size.height <= 0) {
        NSLog(@"Image addition failed:");
        NSLog(@"  - name %@", name);
        NSLog(@"  - offset x:%f y:%f", offset.x, offset.y);
        NSLog(@"  - region x:%f y:%f w:%f h:%f",
              imageRegion.origin.x, imageRegion.origin.y,
              imageRegion.size.width, imageRegion.size.height);
        return nil;
    }
    
    NSData *imageData = PSDImageGetDataInRegion(image, imageRegion);
    if (imageData == nil) {
        NSLog(@"Image data creation failed");
        return nil;
    }
    
    PSDImageLayer *layer = [[PSDImageLayer alloc] init];
    layer.imageData = imageData;
    layer.rect = screenRegion;
    layer.name = name;
    return layer;
}
    
- (void)unsafeAddLayer:(PSDLayer *)layer
{
    [_layers addObject:layer];
}

#pragma mark Manage layers

- (void)setPreview:(CGImageRef)preview
{
    _previewData = PSDImageGetData(preview);
}

- (void)addImage:(CGImageRef)image name:(NSString*)name offset:(CGPoint)offset
{
    PSDLayer *layer = [self createLayerWithImage:image name:name offset:offset];
    if (layer != nil) {
        [self unsafeAddLayer:layer];
    }
}

- (void)openGroupLayerWithName:(NSString *)name
                       opacity:(float)opacity
                      isOpened:(BOOL)isOpened
{
    PSDGroupLayer *headGroupLayer = [[PSDGroupLayer alloc] init];
    headGroupLayer.name = name;
    headGroupLayer.opacity = opacity;
    headGroupLayer.isOpened = isOpened;
    headGroupLayer.isHead = YES;
    [_layers addObject:headGroupLayer];
    [_groups addObject:headGroupLayer];
}

- (void)closeCurrentGroupLayer
{
    if (_groups.count == 0) {
        NSString *reason = @"Cannot close group because no group has been opened.";
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
    }
    
    PSDGroupLayer *headGroupLayer = (PSDGroupLayer *)[_groups lastObject];
    PSDGroupLayer *tailGroupLayer = [[PSDGroupLayer alloc] init];
    tailGroupLayer.name = headGroupLayer.name;
    tailGroupLayer.opacity = headGroupLayer.opacity;
    tailGroupLayer.isOpened = headGroupLayer.isOpened;
    tailGroupLayer.isHead = NO;
    [_layers addObject:tailGroupLayer];
    [_groups removeLastObject];
}

#pragma mark Photoshop constants

- (NSData *)resolutionData
{
    unsigned char resInfo[] = {
        0x00, 0x48, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01,
        0x00, 0x48, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01
    };
    return [NSData dataWithBytes:resInfo length:sizeof(resInfo)];
}

- (NSData *)iccProfile
{
    unsigned char c[] = {
        0x00, 0x00, 0x20, 0x28, 0x41, 0x44, 0x42, 0x45, 0x20,
        0x10, 0x00, 0x00, 0x6D, 0x6E, 0x74, 0x72, 0x52, 0x47,
        0x42, 0x20, 0x58, 0x59, 0x5A, 0x20, 0x70, 0xCF, 0x00,
        0x6, 0x00, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x61, 0x63, 0x73, 0x70, 0x41, 0x50, 0x50, 0x4C, 0x00,
        0x00, 0x00, 0x00, 0x6E, 0x6F, 0x6E, 0x65, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0xF6, 0xD6,
        0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0xD3, 0x2D, 0x41,
        0x44, 0x42, 0x45, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x63, 0x70, 0x72,
        0x74, 0x00, 0x00, 0x00, 0xFC, 0x00, 0x00, 0x00, 0x32,
        0x64, 0x65, 0x73, 0x63, 0x00, 0x00, 0x10, 0x30, 0x00,
        0x00, 0x00, 0x64, 0x77, 0x74, 0x70, 0x74, 0x00, 0x00,
        0x10, 0x94, 0x00, 0x00, 0x00, 0x14, 0x62, 0x6B, 0x70,
        0x74, 0x00, 0x00, 0x10, 0xA8, 0x00, 0x00, 0x00, 0x14,
        0x72, 0x54, 0x52, 0x43, 0x00, 0x00, 0x10, 0xBC, 0x00,
        0x00, 0x00, 0x0E, 0x67, 0x54, 0x52, 0x43, 0x00, 0x00,
        0x10, 0xCC, 0x00, 0x00, 0x00, 0x0E, 0x62, 0x54, 0x52,
        0x43, 0x00, 0x00, 0x10, 0xDC, 0x00, 0x00, 0x00, 0x0E,
        0x72, 0x58, 0x59, 0x5A, 0x00, 0x00, 0x10, 0xEC, 0x00,
        0x00, 0x00, 0x14, 0x67, 0x58, 0x59, 0x5A, 0x00, 0x00,
        0x20, 0x00, 0x00, 0x00, 0x00, 0x14, 0x62, 0x58, 0x59,
        0x5A, 0x00, 0x00, 0x20, 0x14, 0x00, 0x00, 0x00, 0x14,
        0x74, 0x65, 0x78, 0x74, 0x00, 0x00, 0x00, 0x00, 0x43,
        0x6F, 0x70, 0x79, 0x72, 0x69, 0x67, 0x68, 0x74, 0x20,
        0x31, 0x39, 0x39, 0x39, 0x20, 0x41, 0x64, 0x6F, 0x62,
        0x65, 0x20, 0x53, 0x79, 0x73, 0x74, 0x65, 0x6D, 0x73,
        0x20, 0x49, 0x6E, 0x63, 0x6F, 0x72, 0x70, 0x6F, 0x72,
        0x61, 0x74, 0x65, 0x64, 0x00, 0x00, 0x00, 0x64, 0x65,
        0x73, 0x63, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x0A, 0x41, 0x70, 0x70, 0x6C, 0x65, 0x20, 0x52, 0x47,
        0x42, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x58,
        0x59, 0x5A, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0xF3, 0x51, 0x00, 0x10, 0x00, 0x00, 0x00, 0x10, 0x16,
        0xCC, 0x58, 0x59, 0x5A, 0x20, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x63, 0x75, 0x72, 0x76, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x10, 0xCD, 0x00,
        0x00, 0x63, 0x75, 0x72, 0x76, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x10, 0x10, 0xCD, 0x00, 0x00, 0x63,
        0x75, 0x72, 0x76, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x10, 0x10, 0xCD, 0x00, 0x00, 0x58, 0x59, 0x5A,
        0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x79, 0xBD,
        0x00, 0x00, 0x41, 0x52, 0x00, 0x00, 0x40, 0xB9, 0x58,
        0x59, 0x5A, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x56, 0xF8, 0x00, 0x00, 0xAC, 0x2F, 0x00, 0x00, 0x1D,
        0x30, 0x58, 0x59, 0x5A, 0x20, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x26, 0x22, 0x00, 0x00, 0x12, 0x7F, 0x00,
        0x00, 0xB1, 0x70
    };
    return [NSData dataWithBytes:c length:sizeof(c)];
}

#pragma mark Manage data packing

- (void)computePackData
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.qualityOfService = NSOperationQualityOfServiceUserInitiated;
    queue.maxConcurrentOperationCount = 1;//self.maxConcurentOperationsCount;

    for (PSDLayer *layer in _layers) {
        [queue addOperationWithBlock:^{
            [layer generatePackedDataWithDocumentSize:self->_size];
        }];
    }
    [queue addOperationWithBlock:^{
        self->_packedPreviewData = PSDPackedPreviewImageData
        (self->_previewData, self->_size);
    }];
    
    [queue waitUntilAllOperationsAreFinished];
}

- (void)clearPackData
{
    for (PSDLayer *layer in _layers) {
        [layer clearPackedData];
    }
    _packedPreviewData = nil;
}

#pragma mark Create Photoshop data

- (void)appendHeaderToStream:(PSDStream *)stream
{
    // Header block
    [stream writeInt32:'8BPS'];                        // signature
    [stream writeInt16:1];                             // version
    [stream writeInt32:0];                             // reserved
    [stream writeInt16:0];                             // reserved
    
    [stream writeInt16:4];                             // channels
    [stream writeInt32:(int)_size.height];             // height
    [stream writeInt32:(int)_size.width];              // width
    
    [stream writeInt16:8];                             // depth
    [stream writeInt16:PSDRGBMode];                    // color mode
    [stream writeInt32:0];                             // colormap data.
    
    // Image resource blocks
    PSDStream *resourceInfoStream = [PSDStream streamForWritingToMemory];
    if (_includesICC) {
        [resourceInfoStream writeInt32:'8BIM'];
        [resourceInfoStream writeInt16:1039]; // ICC Profile
        [resourceInfoStream writePascalString:@"" withPadding:2];
        [resourceInfoStream writeDataWithLengthHeader:[self iccProfile]];
    }
        
    [resourceInfoStream writeInt32:'8BIM'];
    [resourceInfoStream writeInt16:1005]; // resolution info.
    [resourceInfoStream writePascalString:@"" withPadding:2];
    [resourceInfoStream writeDataWithLengthHeader:[self resolutionData]];
    
    [resourceInfoStream writeInt32:'8BIM'];
    [resourceInfoStream writeInt16:1026]; // layer group info
    [resourceInfoStream writePascalString:@"" withPadding:2];
    PSDStream *groupInfo = [PSDStream streamForWritingToMemory];
    for (int i = 0; i < self.layers.count; i++) { [groupInfo writeInt16:0]; }
    [resourceInfoStream writeDataWithLengthHeader:[groupInfo outputData]];
    
//    [resourceInfoStream writeInt32:'8BIM']; // layer structure
//    [resourceInfoStream writeInt16:1024];
//    [resourceInfoStream writeInt16:0];
//    [resourceInfoStream writeInt16:2];
//    [resourceInfoStream writeInt16:0];      // current layer = 0
    
    [stream writeDataWithLengthHeader:[resourceInfoStream outputData]];
}

- (void)appendLayersToStream:(PSDStream *)stream
{
    PSDStream *layerAndGlobalMaskStream = [PSDStream streamForWritingToMemory];
    
    PSDStream *layerInfoStream = [PSDStream streamForWritingToMemory];
    [layerInfoStream writeSInt16:(_layers.count * -1)];
        
    for (NSInteger i = 0; i < _layers.count; i++) {
        [_layers[i] writeLayerInfoToStream:layerInfoStream documentSize:self.size];
        [_layers[i] writeExtraInfoToStream:layerInfoStream documentSize:self.size];
    }
    for (NSInteger i = 0; i < _layers.count; i++) {
        [_layers[i] writeImageDataToStream:layerInfoStream documentSize:self.size];
    }
    
    while ([[layerInfoStream outputData] length] % 2 != 0) { // rounded to multiple of 2
        [layerInfoStream writeInt8:0];
    }
    
    [layerAndGlobalMaskStream writeDataWithLengthHeader:[layerInfoStream outputData]];
    [layerAndGlobalMaskStream writeInt32:0]; // Len layer mask section
    [stream writeDataWithLengthHeader:[layerAndGlobalMaskStream outputData]];
}

- (void)appendPreviewToStream:(PSDStream *)stream
{
    [stream writeInt16:1];
    [stream writeData:_packedPreviewData];
    [stream close];
}

- (void)checkDocument
{
    if (_previewData == nil) {
        NSString *reason = @"The document contains no preview";
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
    }
    if (_layers.count == 0 && !self.allowEmptyDocument) {
        NSString *reason = @"The document contains no layer";
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
    }
    if (_groups.count > 0) {
        NSString *reason = @"Some opened groups are not closed";
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
    }
}

- (void)writeToFileURL:(NSURL *)fileURL
{
    [self checkDocument];
    
    [self computePackData];
    PSDStream *stream = [PSDStream streamForWritingToURL:fileURL];
    [self appendHeaderToStream:stream];
    [self appendLayersToStream:stream];
    [self appendPreviewToStream:stream];
    [self clearPackData];
}

@end
