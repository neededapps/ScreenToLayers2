
@import Foundation;
@import QuartzCore;

@class PSDStream;

NS_ASSUME_NONNULL_BEGIN

@interface PSDLayer : NSObject

@property (nonatomic, strong, nullable) NSString *name;
@property (nonatomic, assign) float opacity;

- (void)generatePackedDataWithDocumentSize:(CGSize)size;
- (void)clearPackedData;

- (void)writeImageDataToStream:(PSDStream *)stream documentSize:(CGSize)size;
- (void)writeLayerInfoToStream:(PSDStream *)stream documentSize:(CGSize)size;
- (void)writeExtraInfoToStream:(PSDStream *)stream documentSize:(CGSize)size;
    
@end

NS_ASSUME_NONNULL_END
