
@import Foundation;
@import QuartzCore;
@import Cocoa;

NS_ASSUME_NONNULL_BEGIN

@class PSDLayer;

@interface PSDWriter : NSObject

#pragma mark Initializers

- (instancetype)initWithSize:(CGSize)size NS_DESIGNATED_INITIALIZER;

#pragma mark Properties

@property (readonly, nonatomic, assign) BOOL includesICC;
@property (readonly, nonatomic, assign) CGSize size;
@property (readwrite, nonatomic, assign) NSInteger maxConcurentOperationsCount;

#pragma mark Create layers
    
- (nullable PSDLayer *)createLayerWithImage:(CGImageRef)image
                                       name:(NSString *)name
                                     offset:(CGPoint)offset;
- (void)unsafeAddLayer:(PSDLayer *)layer;
    
#pragma mark Manage layers

- (void)setPreview:(CGImageRef)preview;

- (void)addImage:(CGImageRef)image
            name:(NSString *)name
          offset:(CGPoint)offset;

- (void)openGroupLayerWithName:(NSString *)name
                       opacity:(float)opacity
                      isOpened:(BOOL)isOpened;
- (void)closeCurrentGroupLayer;

#pragma mark Data

- (void)writeToFileURL:(NSURL *)fileURL;

@end

NS_ASSUME_NONNULL_END
