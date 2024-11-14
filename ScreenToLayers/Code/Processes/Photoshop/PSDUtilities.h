
@import Foundation;
@import QuartzCore;
@import Accelerate;

#pragma mark - PSD utilities

typedef enum {
    PSDBitmapMode = 0,
    PSDGrayscaleMode = 1,
    PSDIndexedMode = 2,
    PSDRGBMode = 3,
    PSDCMYKMode = 4,
    PSDMultichannelMode = 7,
    PSDDuotoneMode = 8,
    PSDLabMode = 9
} PSDMode;

#pragma mark - Quartz utilities

extern CGPoint PSDCGPointAdd(CGPoint p1, CGPoint p2);
extern CGPoint PSDCGPointSub(CGPoint p1, CGPoint p2);
extern CGPoint PSDCGPointMult(CGPoint point, CGFloat value);
extern CGSize PSDCGSizeMult(CGSize size, CGFloat value);
extern CGRect PSDCGRectMult(CGRect rect, CGFloat value);
extern CGRect PSDCGRectFloor(CGRect rect);
extern CGRect PSDCGRectFromOS(CGPoint origin, CGSize size);


#pragma mark - CGImage utilities

extern NSData *PSDImageGetDataInRegion(CGImageRef imageRef, CGRect region);
extern NSData *PSDImageGetData(CGImageRef imageRef);

#pragma mark - Encoding utilities

extern NSData *PSDEncodedPackBits(char *src, size_t w, size_t h, size_t bytesLength);
extern NSArray *PSDPackedImageData(NSData *data, CGSize size);
extern NSData *PSDPackedPreviewImageData(NSData *data, CGSize size);
