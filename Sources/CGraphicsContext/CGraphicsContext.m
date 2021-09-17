#include "CGraphicsContext.h"

static inline int alphaChannel(uint32_t pixel)
{
#if __BIG_ENDIAN__
    return (pixel & 0xff000000) >> 24;
#else
    // The default byte order in Quartz is big-endian.
    // Our context is set up to have its alpha channel in the most significant byte.
    // So when we cast the big-endian bytes to our little endian uint32_t, we need to
    // look for it in the least significant byte.
    
    return (pixel & 0xff);
#endif
}

CGRect findSmallestBoundingBox(CGContextRef context, long int width, long int height)
{
    uint32_t *pixels = CGBitmapContextGetData(context);
    
#ifndef NDEBUG
    CGImageAlphaInfo bitmapInfo = CGBitmapContextGetAlphaInfo(context);
    assert((bitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaPremultipliedFirst);
    assert((bitmapInfo & kCGBitmapByteOrderMask) == kCGBitmapByteOrderDefault);
#endif
    
    NSInteger top = 0;
    BOOL imageEmpty = YES;
    for (NSInteger y = 0; y < height; ++y) {
        // check if the whole line is empty
        BOOL empty = YES;
        uint32_t *pixel = pixels + (y * width);
        for (NSInteger x = 0; x < width; ++x, ++pixel) {
            if (alphaChannel(*pixel) != 0) {
                empty = NO;
                break;
            }
        }
        
        if (!empty) {
            imageEmpty = NO;
            top = y;
            break;
        }
    }
    
    if (imageEmpty) {
        return CGRectZero;
    }
    
    NSInteger bottom = 0;
    for (NSInteger y = height - 1; y >= 0; --y) {
        // check if the whole line is empty
        BOOL empty = YES;
        uint32_t *pixel = pixels + (y * width);
        for (NSInteger x = 0; x < width; ++x, ++pixel) {
            if (alphaChannel(*pixel) != 0) {
                empty = NO;
                break;
            }
        }
        
        if (!empty) {
            bottom = height - y - 1;
            break;
        }
    }
    
    NSInteger left = width;
    for (NSInteger y = top; y < height - bottom; ++y) {
        // find the width of leading empty pixels
        uint32_t *pixel = pixels + (y * width);
        for (NSInteger x = 0; x < width; ++x, ++pixel) {
            if (alphaChannel(*pixel) != 0) {
                if (left > x) {
                    left = x;
                }
            }
        }
    }
    
    NSInteger right = width;
    for (NSInteger y = top; y < height - bottom; ++y) {
        // find the width of trailing empty pixels
        uint32_t *pixel = pixels + ((y + 1) * width) - 1;
        for (NSInteger x = width; x > 0; --x, --pixel) {
            if (alphaChannel(*pixel) != 0) {
                if (right > width - x) {
                    right = width - x;
                }
            }
        }
    }
    
    return CGRectMake(left, top, width - left - right, height - bottom - top);
}
