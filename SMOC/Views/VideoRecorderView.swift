//
//  VideoRecorderVieww.swift
//  SMOC
//
//  Created by Javier Calatrava on 14/1/25.
//

import SwiftUI
import AVFoundation

struct VideoRecorderView: View {
    @StateObject var videoManager = appSingletons.videoManager
    var body: some View {
        ZStack {
            CameraPreview(session: videoManager.session)
                .edgesIgnoringSafeArea(.all)
            VStack {
                            Spacer()
                            HStack {
                                Button(action: {
                                    videoManager.startRecording()
                                }) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 70, height: 70)
                                }
                                .padding()
                                
                                Button(action: {
                                    videoManager.stopRecording()
                                }) {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                        .frame(width: 70, height: 70)
                                }
                                .padding()
                            }
                        }
        }.onAppear {
            Task {
                await videoManager.setupSession()
            }
        }
        
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspect
        view.videoPreviewLayer.connection?.videoOrientation = .portrait
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}

#Preview {
    VideoRecorderView()
}
