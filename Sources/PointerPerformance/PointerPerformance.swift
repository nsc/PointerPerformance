import CoreGraphics
import CGraphicsContext

fileprivate extension UInt32 {
    var alphaChannel: UInt32 {
        self & 0xff
//        return Int((bigEndian & 0xff000000) >> 24)
    }
}

public struct GraphicsContext {
    private(set) public var cgContext: CGContext
    private(set) public var bounds: CGRect
    
    public init?(with size: CGSize, backgroundColor: CGColor?, colorSpace: CGColorSpace, bitmapInfo: CGBitmapInfo) {
        var size = CGSize(width: ceil(size.width), height: ceil(size.height))
        if size.width * size.height < 1 {
            // MK This can be sometimes the case, so let's be more forgiving and just create a tiny little context
            // FIXME: How can this be?
            size.width = 1
            size.height = 1
        }
        
        var frame: CGRect = .zero
        frame.size.width = round(size.width)
        frame.size.height = round(size.height)
        if frame.size.width < 1 || frame.size.height < 1 {
            return nil
        }
        
        
        let bytesPerPixel = colorSpace.numberOfComponents * (bitmapInfo.contains(.floatComponents) ? 4 : 1) +
                                                             (((bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue) == CGImageAlphaInfo.none.rawValue) ? 0 : 1)
        
        let bytesPerRow = Int(frame.size.width) * bytesPerPixel
        
        self.init(size: frame.size,
                  bytePerPixel: bytesPerPixel,
                  bytesPerRow: bytesPerRow,
                  colorSpace: colorSpace,
                  bitmapInfo: bitmapInfo)

        
        // Setting the background color is only required, if it is not clearColor
        if let backgroundColor = backgroundColor {
            cgContext.saveGState()
            cgContext.setBlendMode(CGBlendMode.copy)
            cgContext.setFillColor(backgroundColor)
            cgContext.fill(frame)
            cgContext.restoreGState()
        }
    }

    public init?(size: CGSize, bytePerPixel: Int, bytesPerRow: Int, colorSpace: CGColorSpace, bitmapInfo: CGBitmapInfo) {
        guard let cgContext = CGContext(data: nil,
                                        width: Int(size.width),
                                        height: Int(size.height),
                                        bitsPerComponent: 8,
                                        bytesPerRow: bytesPerRow,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo.rawValue) else {
            
            return nil
        }
        
        self.init(cgContext: cgContext, bounds: CGRect(origin: .zero, size: size))
    }

    public init?(size: CGSize, backgroundColor: CGColor? = nil) {
        let alphaInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
        let colorspace = CGColorSpaceCreateDeviceRGB()
        
        self.init(with: size, backgroundColor: backgroundColor, colorSpace: colorspace, bitmapInfo:CGBitmapInfo(rawValue: alphaInfo))
    }
    
    public init(cgContext: CGContext, bounds: CGRect) {
        self.cgContext = cgContext
        self.bounds = bounds
    }
    
    public func findSmallestBoundingBox() -> CGRect {
        findSmallestBoundingBox_1()
    }
    
    public func findSmallestBoundingBox_c() -> CGRect {
        CGraphicsContext.findSmallestBoundingBox(cgContext, Int(round(bounds.size.width)), Int(round(bounds.size.height)))

    }
    
////    @_specialize(where T == UInt32)
//    public func findSmallestBoundingBox<T : FixedWidthInteger>(_ type: T.Type) -> CGRect {

    public func findSmallestBoundingBox_1() -> CGRect {

        guard let bytes = cgContext.data else {
            return .zero
        }
        
        let pixels = bytes.assumingMemoryBound(to: UInt32.self)

        let bitmapInfo = cgContext.alphaInfo
        precondition((bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue) == CGImageAlphaInfo.premultipliedFirst.rawValue)
        precondition((bitmapInfo.rawValue & CGBitmapInfo.byteOrderMask.rawValue) == CGImageByteOrderInfo.orderDefault.rawValue)
        
        let size = bounds.size
        let width = Int(size.width)
        let height = Int(size.height)
        
        var top = 0;
        var imageEmpty = true
        for y in 0..<height {
            // check if the whole line is empty
            var empty = true
            var pixel = pixels + (y * width)
            for _ in 0..<width {
                if pixel.pointee & 0xff != 0 {
                    empty = false
                    break;
                }
                pixel += 1
            }
            
            if !empty {
                imageEmpty = false
                top = y
                break
            }
        }
        
        if imageEmpty {
            return .zero
        }
        
        var bottom = 0
        for y in (0..<height).reversed() {
            // check if the whole line is empty
            var empty = true
            var pixel = pixels + (y * width)
            for _ in 0..<width {
                if pixel.pointee & 0xff != 0 {
                    empty = false
                    break;
                }
                pixel += 1
            }
            
            if !empty {
                bottom = height - y - 1;
                break;
            }
        }
        
        var left = width
        for y in top..<(height - bottom) {
            // find the width of leading empty pixels
            var pixel = pixels + (y * width)
            for x in 0..<width {
                if pixel.pointee & 0xff != 0 {
                    if left > x {
                        left = x
                    }
                }
                pixel += 1
            }
        }
        
        var right = width
        for y in top..<(height - bottom) {
            // find the width of trailing empty pixels
            var pixel = pixels + ((y + 1) * width) - 1
            for x in (1...width).reversed() {
                if pixel.pointee & 0xff != 0 {
                    if right > width - x {
                        right = width - x
                    }
                }
                pixel -= 1
            }
        }
        
        return CGRect(x: left,
                      y: top,
                      width: width - left - right,
                      height: height - bottom - top)
    }

    public func findSmallestBoundingBox_2() -> CGRect {

        guard let bytes = cgContext.data else {
            return .zero
        }
        
        let pixels = bytes.assumingMemoryBound(to: UInt32.self)

        let bitmapInfo = cgContext.alphaInfo
        precondition((bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue) == CGImageAlphaInfo.premultipliedFirst.rawValue)
        precondition((bitmapInfo.rawValue & CGBitmapInfo.byteOrderMask.rawValue) == CGImageByteOrderInfo.orderDefault.rawValue)
        
        let size = bounds.size
        let width = Int(size.width)
        let height = Int(size.height)
        
        var top = 0;
        var imageEmpty = true
        for y in 0..<height {
            // check if the whole line is empty
            var empty = true
            var pixel = pixels + (y * width)
            var x = 0
            while x < width {
                if pixel.pointee & 0xff != 0 {
                    empty = false
                    break;
                }
                pixel += 1
                x += 1
            }
            
            if !empty {
                imageEmpty = false
                top = y
                break
            }
        }
        
        if imageEmpty {
            return .zero
        }
        
        var bottom = 0
        for y in (0..<height).reversed() {
            // check if the whole line is empty
            var empty = true
            var pixel = pixels + (y * width)
            var x = 0
            while x < width {
                if pixel.pointee & 0xff != 0 {
                    empty = false
                    break;
                }
                pixel += 1
                x += 1
            }
            
            if !empty {
                bottom = height - y - 1;
                break;
            }
        }
        
        var left = width
        for y in top..<(height - bottom) {
            // find the width of leading empty pixels
            var pixel = pixels + (y * width)
            var x = 0
            while x < width {
                if pixel.pointee & 0xff != 0 {
                    if left > x {
                        left = x
                    }
                }
                pixel += 1
                x += 1
            }
        }
        
        var right = width
        for y in top..<(height - bottom) {
            // find the width of trailing empty pixels
            var pixel = pixels + ((y + 1) * width) - 1
            var x = width
            while x > 0 {
                if pixel.pointee & 0xff != 0 {
                    if right > width - x {
                        right = width - x
                    }
                }
                pixel -= 1
                x -= 1
            }
        }
        
        return CGRect(x: left,
                      y: top,
                      width: width - left - right,
                      height: height - bottom - top)
    }
}
