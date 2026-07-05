import Foundation
import UIKit

public class MJPEGStreamReader {
    private var buffer = Data()
    private let queue = DispatchQueue(label: "com.choicetech.sdk.chp.streamParserQueue")
    
    public var onFrameDecoded: ((UIImage) -> Void)?
    public var onStreamStop: (() -> Void)?
    
    // FPS statistics variables
    private var frameCounter = 0
    private var lastFrameTime = Date()
    private var bytesAccumulator = 0
    
    public var onStatsUpdated: ((Double, Double) -> Void)? // (FPS, Kbps)
    
    public init() {}
    
    public func reset() {
        queue.async {
            self.buffer.removeAll()
            self.frameCounter = 0
            self.bytesAccumulator = 0
            self.lastFrameTime = Date()
        }
    }
    
    public func parseBytes(_ data: Data) {
        queue.async {
            self.buffer.append(data)
            self.bytesAccumulator += data.count
            self.parseBuffer()
        }
    }
    
    private func parseBuffer() {
        while true {
            guard buffer.count > 4 else { return }
            
            // Find SOI (Start of Image) : 0xFFD8
            guard let soiIndex = findSOI() else {
                // If no SOI is found, but we have data, we might be in the middle of a frame.
                // Clear everything except the last byte in case it's 0xFF
                if buffer.count > 1 {
                    buffer.removeSubrange(0..<(buffer.count - 1))
                }
                return
            }
            
            // Find EOI (End of Image) : 0xFFD9
            guard let eoiIndex = findEOI(startingFrom: soiIndex + 2) else {
                // SOI is found, but EOI is not fully received yet. Keep waiting.
                // If buffer is extremely large, clear stale data before SOI
                if soiIndex > 0 {
                    buffer.removeSubrange(0..<soiIndex)
                }
                return
            }
            
            let frameData = buffer.subdata(in: soiIndex..<eoiIndex)
            buffer.removeSubrange(0..<eoiIndex)
            
            // Decode JPEG Frame
            if let image = UIImage(data: frameData) {
                calculateStats(frameSize: frameData.count)
                DispatchQueue.main.async {
                    self.onFrameDecoded?(image)
                }
            }
        }
    }
    
    private func findSOI() -> Int? {
        for i in 0..<(buffer.count - 1) {
            if buffer[i] == 0xFF && buffer[i+1] == 0xD8 {
                return i
            }
        }
        return nil
    }
    
    private func findEOI(startingFrom index: Int) -> Int? {
        guard index < buffer.count - 1 else { return nil }
        for i in index..<(buffer.count - 1) {
            if buffer[i] == 0xFF && buffer[i+1] == 0xD9 {
                return i + 2 // Return index after EOI
            }
        }
        return nil
    }
    
    private func calculateStats(frameSize: Int) {
        frameCounter += 1
        if frameCounter % 30 == 0 {
            let now = Date()
            let elapsed = now.timeIntervalSince(lastFrameTime)
            if elapsed > 0 {
                let fps = 30.0 / elapsed
                let kbps = (Double(bytesAccumulator) * 8.0) / (elapsed * 1000.0)
                bytesAccumulator = 0
                lastFrameTime = now
                
                DispatchQueue.main.async {
                    self.onStatsUpdated?(fps, kbps)
                }
            }
        }
    }
}
