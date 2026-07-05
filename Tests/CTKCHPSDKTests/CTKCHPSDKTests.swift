import XCTest
@testable import CTKCHPSDK

final class CTKCHPSDKTests: XCTestCase {
    func testPacketParsing() {
        let notiPacket = CHPPacket.parse("{noti:camfps:15}")
        XCTAssertNotNil(notiPacket)
        XCTAssertEqual(notiPacket?.cmd, "camfps")
        XCTAssertEqual(notiPacket?.params.first, "15")
        
        let responsePacket = CHPPacket.parse("{y:knock}")
        XCTAssertNotNil(responsePacket)
        XCTAssertEqual(responsePacket?.cmd, "knock")
        XCTAssertEqual(responsePacket?.status, "y")
    }
}
