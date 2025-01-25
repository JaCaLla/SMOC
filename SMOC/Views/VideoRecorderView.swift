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
    @StateObject var locationManager = appSingletons.locationManager
    @Environment(\.scenePhase) var scenePhase
    @State private var isShowingDetail = false
    let lowOpacity = 0.6
    let highOpacity = 0.45
    let progressHeight = 5.0

    var body: some View {
        ZStack {
            if scenePhase == .active {
                CameraPreview(session: videoManager.avCaptureSession)
                    .edgesIgnoringSafeArea(.all)
            }
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    videoRecorerHeaderView()
                    Spacer()
                    speedMeterView()
                    Spacer()
                    recorderButton()
                    progressView()
                }
            }
            if isShowingDetail {
                ConfigurationView(isShowingDetail: $isShowingDetail)
                    .transition(.move(edge: .trailing))
                    .animation(.easeInOut, value: isShowingDetail)
            }
        }.onAppear {
            setupSessionAndStartRecording()
        }.onChange(of: scenePhase) { _, newPhase in
            onChangeScene(newPhase)
        }.onRotate { newOrientation in
            reStartRecording()
        }
    }

    func videoRecorerHeaderView() -> some View {
        guard let townAndProvince = locationManager.townAndProvince else {
            return AnyView(EmptyView())
        }
        return AnyView(
            HStack {
                Spacer()
                Text(townAndProvince)
                    .font(.townProviceFont)
                Spacer()
                Button(action: {
                    withAnimation {
                        isShowingDetail = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 40, height: 40)
                        Image(systemName: "gearshape.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor( .gray)
                    }.opacity(highOpacity)
                }.padding()
            }


        )
    }

    func speedMeterView() -> some View {
        guard let currentSpeed = locationManager.currentSpeed,
            let currentSpeedUnits = locationManager.currentSpeedUnits else {
            return AnyView(EmptyView())
        }
        return AnyView(HStack(alignment: .lastTextBaseline) {
                Text(currentSpeed)
                    .font(.currentSpeedFont)
                Text(currentSpeedUnits)
                    .font(.currentSpeedUnitsFont)

            })
    }

    func progressView() -> some View {
        switch videoManager.state {
        case .notStarted, .ready, .transferingToReel:
            return AnyView(Spacer().frame(height: progressHeight))
        case .preRecording, .postRecording:
            return AnyView(
                ProgressView(value: min(videoManager.progress, 1.0), total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                    .opacity(lowOpacity)
                    .frame(height: progressHeight)
            )
        }
    }

    func onChangeScene(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            setupSessionAndStartRecording()
            print("La aplicación está activa.")
        case .inactive:
            print("La aplicación está inactivation.")
            Task {
                await videoManager.stopSession()
            }
        case .background:
            print("La aplicación está en background.")
            Task {
                await videoManager.stopSession()
            }
        @unknown default: break
        }
    }


    func recorderButton() -> some View {
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
    }

    func progressView(
        for state: VideoManagerState,
        progress: Binding<Double>,
        progressHeight: CGFloat,
        lowOpacity: Double
    ) -> some View {
        switch state {
        case .notStarted, .ready, .transferingToReel:
            return AnyView(Spacer().frame(height: progressHeight))
        case .preRecording, .postRecording:
            return AnyView(
                ProgressView(value: progress.wrappedValue, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                    .opacity(lowOpacity)
                    .frame(height: progressHeight)
            )
        }
    }

    func reStartRecording() {
        Task {
            await videoManager.reStartRecording()
        }
    }

    func setupSessionAndStartRecording() {
        Task {
            await videoManager.setupSessionAndStartRecording()
        }
    }

    func stopSession() {
        Task {
            await videoManager.stopSession()
        }
    }

}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            action(UIDevice.current.orientation)
        }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
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

        if [.landscapeLeft, .landscapeRight].contains(where: { UIDevice.current.videoOrientation == $0 }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                context.coordinator.updateVideoOrientation()
            }
        }

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
                else {
                return
            }

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
