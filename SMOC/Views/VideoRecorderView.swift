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
   // @State private var progress = 0.0
   // @State private var timerRunning = false
    var body: some View {
        ZStack {
            CameraPreview(session: videoManager.session)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text(videoManager.state.description())
                Text("\(videoManager.progress)")
                Spacer()
                if videoManager.recorderReady {
                    Button(action: {
                   //     startTimer(duration: videoManager.postRecordingSecs)
                        videoManager.stopRecording()
                    }) {
                        Circle()
                            .fill( Color.red)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                    }
                    .padding()
                }
                switch videoManager.state {
                case .notStarted:
                    EmptyView()
                case .preRecording:
                    ProgressView(value: videoManager.progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                case .ready:
                    EmptyView()
                case .postRecording:
                    ProgressView(value: videoManager.progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                case .transferingToReel:
                    EmptyView()
                
                }
                    
               
            }
        }.onAppear {
          //  startTimer(duration: videoManager.preRecordingSecs)
            startRecording()
        }.onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                startRecording()
                print("La aplicación está activa.")
            case .inactive:
                videoManager.stopSession(true)
                print("La aplicación está inactiva.")
            case .background:
                print("La aplicación está en segundo plano.")
            @unknown default:
                print("Un estado desconocido ocurrió.")
            }
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
