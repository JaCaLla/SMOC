//
//  ConfigurationView.swift
//  SMOC
//
//  Created by Javier Calatrava on 25/1/25.
//

import SwiftUI

enum AppStorageVar: String {
    case preRecordingSecs
    case postRecordingSecs
    case motionThreshold
    case speedSignalDetection
}

struct AppStorageDefaultValues {
    static let preRecordingSecs: Double = 5.0
    static let postRecordingSecs: Double = 5.0
    static let motionThreshold: Double = 2.0
    static let speedSignalDetection: Bool = true
}

struct ConfigurationView: View {
    @Binding var isShowingDetail: Bool
    @StateObject var videoManager = appSingletons.videoManager
    
    @State private var preRecordingSecsSlider: Double = 0.0
    @AppStorage(AppStorageVar.preRecordingSecs.rawValue) private var preRecordingSecs = AppStorageDefaultValues.preRecordingSecs
    
    @State private var postRecordingSecsSlider: Double = 0.0
    @AppStorage(AppStorageVar.postRecordingSecs.rawValue) private var postRecordingSecs = AppStorageDefaultValues.postRecordingSecs
    
    @State private var motionThresholdSlider: Double = 0.0
    @AppStorage(AppStorageVar.motionThreshold.rawValue) private var motionThreshold = AppStorageDefaultValues.motionThreshold
    
    @State private var speedSignalDetectionSwitch: Bool = false
    @AppStorage(AppStorageVar.speedSignalDetection.rawValue) private var speedSignalDetection = AppStorageDefaultValues.speedSignalDetection
    
    var body: some View {
        Form {
            prepostSection(header: "pre_recording_secs", value: $preRecordingSecsSlider)
            prepostSection(header: "post_recording_secs", value: $postRecordingSecsSlider)
            motionThresholSection(header: "motion_threshold_trigger_record", value: $motionThresholdSlider, range: 1...5)
            motionBooleanSection(header: "experimental", value: $speedSignalDetectionSwitch)
        }.onChange(of: preRecordingSecsSlider) { _, newValue in
            preRecordingSecs = newValue
        }.onChange(of: postRecordingSecsSlider) { _, newValue in
            postRecordingSecs = newValue
        }.onChange(of: motionThresholdSlider) { _, newValue in
            motionThreshold = newValue
        }.onChange(of: speedSignalDetectionSwitch) { _, newValue in
            speedSignalDetection = newValue
        }.onAppear {
            Task {
                await videoManager.stopSession()
            }
            preRecordingSecsSlider = Double(preRecordingSecs)
            postRecordingSecsSlider = Double(postRecordingSecs)
            motionThresholdSlider = Double(motionThreshold)
            speedSignalDetectionSwitch = speedSignalDetection
        }.onDisappear(perform: {
            Task {
                await videoManager.setupSessionAndStartRecording()
            }
        })
        .onTapGesture {
            isShowingDetail.toggle()
        }
    }
    
    private func motionBooleanSection(header: LocalizedStringResource, value: Binding<Bool>) -> some View {
        Section {
            Toggle("speed_signal_detection", isOn: value)
        } header: {
            Text(String(format: String(localized: header), value.wrappedValue))
        }
    }
    
    private func motionThresholSection(header: LocalizedStringResource, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        Section {
            Slider(value: value,
                   in: range,
                   step: 1,
                   minimumValueLabel: Text("\(Int(range.lowerBound))"),
                   maximumValueLabel:  Text(">=\(Int(range.upperBound))")) {
                EmptyView()
            }
        } header: {
            Text(String(format: String(localized: header), value.wrappedValue))
        }
    }
    
    private func prepostSection(header: LocalizedStringResource, value: Binding<Double>, range: ClosedRange<Double> = 1...10) -> some View {
        Section {
            Slider(value: value,
                   in: range,
                   step: 1,
                   minimumValueLabel: Text("one_sec"),
                   maximumValueLabel:  Text("ten_secs")) {
                EmptyView()
            }
        } header: {
            Text(String(format: String(localized: header), value.wrappedValue))
        }
    }
}

#Preview {
    ConfigurationView(isShowingDetail: .constant(true))
}
