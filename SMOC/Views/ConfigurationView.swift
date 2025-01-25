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
}

struct AppStorageDefaultValues {
    static let preRecordingSecs: Double = 5.0
    static let postRecordingSecs: Double = 5.0
}

struct ConfigurationView: View {
    @Binding var isShowingDetail: Bool
    @StateObject var videoManager = appSingletons.videoManager
    
    @State private var preRecordingSecsSlider: Double = 0.0
    @AppStorage(AppStorageVar.preRecordingSecs.rawValue) private var preRecordingSecs = AppStorageDefaultValues.preRecordingSecs
    
    @State private var postRecordingSecsSlider: Double = 0.0
    @AppStorage(AppStorageVar.postRecordingSecs.rawValue) private var postRecordingSecs = AppStorageDefaultValues.postRecordingSecs
    
    var body: some View {
        Form {
            prepostSection(header: "pre_recording_secs", value: $preRecordingSecsSlider)
            prepostSection(header: "post_recording_secs", value: $postRecordingSecsSlider)
        }.onChange(of: preRecordingSecsSlider) { _, newValue in
            preRecordingSecs = newValue
        }.onChange(of: postRecordingSecsSlider) { _, newValue in
            postRecordingSecs = newValue
        }.onAppear {
            Task {
                await videoManager.stopSession()
            }
            preRecordingSecsSlider = Double(preRecordingSecs)
            postRecordingSecsSlider = Double(postRecordingSecs)
        }.onDisappear(perform: {
            Task {
                await videoManager.setupSessionAndStartRecording()
            }
        })
        .onTapGesture {
            isShowingDetail.toggle()
        }
    }
    
    private func prepostSection(header: LocalizedStringResource, value: Binding<Double>) -> some View {
        Section {
            Slider(value: value,
                   in: 1...10,
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
