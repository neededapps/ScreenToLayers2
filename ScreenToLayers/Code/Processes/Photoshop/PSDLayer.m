
#import "PSDLayer.h"
#import "PSDUtilities.h"

@implementation PSDLayer

#pragma mark Initializers

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.opacity = 1.0;
        self.name = @"Untitled";
    }
    return self;
}

#pragma mark Generate data

- (void)generatePackedDataWithDocumentSize:(CGSize)size
{
    NSAssert(NO, @"generatePackedDataWithDocumentSize should be overridden.");
}

- (void)clearPackedData {
    NSAssert(NO, @"clearPackedData should be overridden.");
}

- (void)writeImageDataToStream:(PSDStream *)stream documentSize:(CGSize)size
{
    NSAssert(NO, @"writeImageDataToStream should be overridden.");
    return;
}

- (void)writeLayerInfoToStream:(PSDStream *)stream documentSize:(CGSize)size
{
    NSAssert(NO, @"writeLayerInfoToStream should be overridden.");
    return;
}

- (void)writeExtraInfoToStream:(PSDStream *)stream documentSize:(CGSize)size
{
    NSAssert(NO, @"writeLayerInfoToStream should be overridden.");
    return;
}

@end
