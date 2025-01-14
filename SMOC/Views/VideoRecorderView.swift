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
    @State private var orientation = UIDeviceOrientation.unknown
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
        }.onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = UIDevice.current.orientation
        }
        
    }
}

struct CameraPreview: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }

    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let videoPreviewView = VideoPreviewView()
        videoPreviewView.videoPreviewLayer.session = session
        videoPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill

        context.coordinator.previewLayer = videoPreviewView.videoPreviewLayer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            context.coordinator.orientationChanged()
        }

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        
        return videoPreviewView
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    class Coordinator {
            var previewLayer: AVCaptureVideoPreviewLayer?
            
            @objc func orientationChanged() {
                guard let previewLayer = previewLayer,
                      let connection = previewLayer.connection,
                      connection.isVideoOrientationSupported else { return }

                connection.videoOrientation = getVideoOrientation(from: UIDevice.current.orientation)
            }
            
            private func getVideoOrientation(from deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
                switch deviceOrientation {
                case .portrait:
                    return .portrait
                case .landscapeLeft:
                    return .landscapeRight
                case .landscapeRight:
                    return .landscapeLeft
                case .portraitUpsideDown:
                    return .portraitUpsideDown
                default:
                    return .portrait // Valor predeterminado
                }
            }
        }
}

#Preview {
    VideoRecorderView()
}
