import XCTest
import PointerPerformance

final class PointerPerformanceTests: XCTestCase {
    
    func test_findSmallestBoundingBox_c() throws {
        fillContextAndMeasure({ context in
            context.findSmallestBoundingBox_c()
        })
    }

    func test_findSmallestBoundingBox_1() throws {
        fillContextAndMeasure({ context in
            context.findSmallestBoundingBox_1()
        })
    }

    func test_findSmallestBoundingBox_2() throws {
        fillContextAndMeasure({ context in
            context.findSmallestBoundingBox_2()
        })
    }

    func fillContextAndMeasure( _ block: (GraphicsContext) -> CGRect) {
        let size = CGSize(width: 1000, height: 1000)
        guard let context = GraphicsContext(size: size) else {
            XCTFail()
            return
        }
        
        let fillRect = CGRect(origin: .zero, size: size).insetBy(dx: 200, dy: 200)
        
        context.cgContext.setFillColor(.black)
        context.cgContext.fill(fillRect)

        let rect = block(context)
        XCTAssert(rect == fillRect)
        
        measure {
            _ = block(context)
        }
    }
}
