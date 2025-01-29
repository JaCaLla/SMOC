//
//  MotionManager.swift
//  SMOC
//
//  Created by Javier Calatrava on 28/1/25.
//
import Combine
import CoreMotion
import SwiftUI


@GlobalManager
class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    
    @AppStorage(AppStorageVar.motionThreshold.rawValue) private var motionThreshold = AppStorageDefaultValues.motionThreshold
    
    @MainActor
    @Published var motionAlarm = false
    private var internalMotionAlarm = false {
         didSet {
            Task { [internalMotionAlarm] in
                await MainActor.run {
                    self.motionAlarm = internalMotionAlarm
                }
            }
        }
    }
    
    @MainActor
    @Published var acceleration = 0.0
    private var internalAcceleration = 0.0 {
         didSet {
            Task { [internalAcceleration] in
                await MainActor.run {
                    self.acceleration = internalAcceleration
                }
            }
        }
    }
    
    @MainActor
    init() {
        Task {
            await startGyroscope()
        }
    }
    
    var removeMaxTimeout = false
    func startGyroscope() async {
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1 
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                if let data = data, let self {
                    let max = max(abs(data.acceleration.x) , max( abs(data.acceleration.y) , abs(data.acceleration.z)))
                    if max > self.internalAcceleration {
                        self.internalAcceleration =  max
                    } else {
                        guard !removeMaxTimeout else { return }
                        removeMaxTimeout = true
                        let deadline = 3.0
                        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3.0) { [weak self] in
                            Task { @GlobalManager in
                                guard let self else {
                                    return
                                }
                                self.internalAcceleration = 0.0
                                self.removeMaxTimeout = false
                            }
                        }
                    }
                    
                   
                    if !self.internalMotionAlarm && max > motionThreshold {
                        self.internalMotionAlarm = true
                        let deadline = 3.0
                        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + (deadline)) { [weak self] in
                            Task { @GlobalManager in
                                guard let self else {
                                    return
                                }
                                self.internalMotionAlarm = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    func stopGyroscope() {
        motionManager.stopGyroUpdates()
    }
}


