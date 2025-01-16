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
    @Environment(\.scenePhase) var scenePhase
    let lowOpacity = 0.6
    let highOpacity = 0.45
    let progressHeight = 5.0
    
    var body: some View {
        ZStack {
            CameraPreview(session: videoManager.session)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    Button(action: {
                        Task {
                            await videoManager.stopRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 100, height: 100)
                            Image(systemName: videoManager.state.sfSymbolName())
                                .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(videoManager.state == .ready ? .red : .gray)
                        }.opacity(videoManager.state == .ready ? lowOpacity : highOpacity)

                    }
                    .padding()
                    progressView(for: videoManager.state, progress: videoManager.progress, progressHeight: progressHeight, lowOpacity: lowOpacity)
//                    switch videoManager.state {
//                    case .notStarted, .ready, .transferingToReel:
//                        Spacer().frame(height: progressHeight)
//                    case .preRecording, .postRecording:
//                        let progressValue = videoManager.state == .postRecording ? min(videoManager.progress, 1.0) : videoManager.progress
//                        ProgressView(value: progressValue, total: 1.0)
//                            .progressViewStyle(LinearProgressViewStyle(tint: .gray))
//                            .opacity(lowOpacity)
//                            .frame(height: progressHeight)
//                    }
                }
                    
               
            }
        }.onAppear {
          //  startTimer(duration: videoManager.preRecordingSecs)
            startRecording()
        }.onChange(of: scenePhase) { newPhase, _ in
            switch newPhase {
            case .active:
                startRecording()
                print("La aplicación está activa.")
            case .inactive:
                Task {
                    await videoManager.stopSession(true)
                }
            case .background: break
            @unknown default: break
            }
        }
    }
    
    func progressView(for state: VideoManagerState, progress: Double, progressHeight: CGFloat, lowOpacity: Double) -> some View {
        switch state {
        case .notStarted, .ready, .transferingToReel:
            return AnyView(Spacer().frame(height: progressHeight))
        case .preRecording, .postRecording:
            let progressValue = state == .postRecording ? min(progress, 1.0) : progress
            return AnyView(
                ProgressView(value: progressValue, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                    .opacity(lowOpacity)
                    .frame(height: progressHeight)
            )
        }
    }
    
    func startRecording() {
        Task {
            await videoManager.setupSession()
            videoManager.startRecording()
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }

    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewView {
        let videoPreviewView = VideoPreviewView()
        let previewLayer = videoPreviewView.videoPreviewLayer
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        
        context.coordinator.previewLayer = previewLayer
        
        DispatchQueue.main.async {
            context.coordinator.updateVideoOrientation()
        }
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinchGesture(_:)))
        videoPreviewView.addGestureRecognizer(pinchGesture)

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.updateVideoOrientation),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )

        return videoPreviewView
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var lastOrientation: AVCaptureVideoOrientation = .portrait
        
        @objc func updateVideoOrientation() {
            guard
                let previewLayer = previewLayer,
                let connection = previewLayer.connection,
                connection.isVideoOrientationSupported
            else { return }
            
            let orientation = UIDevice.current.videoOrientation
            connection.videoOrientation = orientation
            if orientation == .portraitUpsideDown {
                switch lastOrientation {
                           case .portrait:
                               previewLayer.setAffineTransform(CGAffineTransform.identity.rotated(by: .pi))
                           case .landscapeLeft:
                               previewLayer.setAffineTransform(CGAffineTransform.identity.rotated(by: -.pi / 2))
                           case .landscapeRight:
                               previewLayer.setAffineTransform(CGAffineTransform.identity.rotated(by: .pi / 2))
                           default: 
                               previewLayer.setAffineTransform(.identity)
                           }
            } else {
                previewLayer.setAffineTransform(.identity)
            }
            lastOrientation = orientation
        }
        
        @MainActor
        @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
            Task {
                await appSingletons.videoManager.handlePinchGesture(gesture)
            }
            
        }
    }
}

private extension UIDevice {
    var videoOrientation: AVCaptureVideoOrientation {
        switch orientation {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }
}

#Preview {
    VideoRecorderView()
}
