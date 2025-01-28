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
    @Published var rotationRate = 0.0
    private var internalRotationRate = 0.0 {
         didSet {
            Task { [internalRotationRate] in
                await MainActor.run {
                    self.rotationRate = internalRotationRate
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
            motionManager.gyroUpdateInterval = 0.1 // Intervalo de actualización (en segundos)
            motionManager.startGyroUpdates(to: .main) { [weak self] (data, error) in
                if let data = data, let self {
                    let max = max(abs(data.rotationRate.x) , max( abs(data.rotationRate.y) , abs(data.rotationRate.z)))
                    if max > self.internalRotationRate {
                        self.internalRotationRate =  max
                    } else {
                        guard !removeMaxTimeout else { return }
                        removeMaxTimeout = true
                        let deadline = 3.0
                        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3.0) { [weak self] in
                            Task { @GlobalManager in
                                guard let self else {
                                    return
                                }
                                self.internalRotationRate = 0.0
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


