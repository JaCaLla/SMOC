//
//  VideoManager+AVCaptureVideoData.swift
//  SMOC
//
//  Created by Javier Calatrava on 28/1/25.
//

import AVFoundation
import Foundation
import UIKit
import Vision
import SwiftUI

extension VideoManager: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self,
                  let observations = request.results as? [VNRecognizedTextObservation],
                  let topCandidate = self.getCandidate(from: observations)/*observations.first?.topCandidates(1).first*/ else {
                return
            }

            print("String: \(topCandidate)")
            if let speedCandidate = Int(topCandidate),
               (10...130).contains(speedCandidate),
               speedCandidate % 10 == 0  {
                print("Speed candidate: \(speedCandidate)")
                self.internalMaxSpeedSignal = speedCandidate
            }
        }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing text recognition: \(error)")
        }
    }
    
    private func getCandidate(from observations: [VNRecognizedTextObservation]) -> String? {
        var candidates = [String]()
        for observation in observations {
            for candidate in observation.topCandidates(10) {
                if candidate.confidence > 0.9,
                   let speedCandidate = Int(candidate.string),
                     (10...130).contains(speedCandidate),
                     speedCandidate % 10 == 0 {
                    candidates.append(candidate.string)
                }
            }
        }
        return candidates.firstMostCommonItemRepeated()
    }
}

extension Array where Element == String {
    func firstMostCommonItemRepeated() -> String? {
        var counting = [String: Int]() 

        for element in self {
            counting[element, default: 0] += 1
        }

        return counting.max { $0.value < $1.value }?.key
    }
}
