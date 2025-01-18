//
//  LocationManager.swift
//  SMOC
//
//  Created by Javier Calatrava on 16/1/25.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject  {
    private var locationManager = CLLocationManager()

    @MainActor
    @Published var permissionGranted: Bool = false
    private var internalPermissionGranted: Bool = false {
         didSet {
            Task { [internalPermissionGranted] in
                await MainActor.run {
                    self.permissionGranted = internalPermissionGranted
                }
            }
        }
    }
    
    @MainActor
    @Published var currentSpeed: String?
    private var internalCurrentSpeed: String? {
         didSet {
            Task { [internalCurrentSpeed] in
                await MainActor.run {
                    self.currentSpeed = internalCurrentSpeed
                }
            }
        }
    }
    
    @MainActor
    @Published var currentSpeedUnits: String?
    private var internalCurrentSpeedUnits: String? {
         didSet {
            Task { [internalCurrentSpeedUnits] in
                await MainActor.run {
                    self.currentSpeedUnits = internalCurrentSpeedUnits
                }
            }
        }
    }
    
    @MainActor
    @Published var townAndProvince: String?
    private var internalTownAndProvince: String? {
         didSet {
            Task { [internalTownAndProvince] in
                await MainActor.run {
                    self.townAndProvince = internalTownAndProvince
                }
            }
        }
    }
    
    @MainActor
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func checkPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let statuses: [CLAuthorizationStatus] = [.authorizedWhenInUse, .authorizedAlways]
        if statuses.contains(status) {
            internalPermissionGranted = true
            //DispatchQueue.global().asyncAfter(deadline: .now()) { [weak self] in
            Task {
                startUpdatingLocation()
            }
        //    startUpdatingLocation()
        } else if status == .notDetermined {
            checkPermission()
        } else {
            internalPermissionGranted = false
        }
    }
    
  //  @GlobalManager
    private func startUpdatingLocation() {
       // Task {
            guard CLLocationManager.locationServicesEnabled() else { return }
            locationManager.startUpdatingLocation()
       // }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        internalCurrentSpeed = getSpeed(location)
        internalCurrentSpeedUnits = getSpeedUnits(location)
        Task {
            await getCountryName(for: location)
        }
    }
    
    private func getSpeed(_ currentLocation: CLLocation) -> String {
//        let speedValue = max(0, currentLocation.speed)
//        let speedInCorrectUnit = isMetric() ? speedValue * 3.6 : speedValue * 2.23694
//        return String(format: "%d", speedInCorrectUnit)
        let speedMeasurement = Measurement(value: max(0, currentLocation.speed), unit: UnitSpeed.metersPerSecond)
        let localizedUnit: UnitSpeed = {
                if #available(iOS 16.0, *) {
                    return Locale.current.measurementSystem == .metric ? UnitSpeed.kilometersPerHour : UnitSpeed.milesPerHour
                } else {
                    return Locale.current.usesMetricSystem ? UnitSpeed.kilometersPerHour : UnitSpeed.milesPerHour
                }
            }()
        let localizedSpeed = speedMeasurement.converted(to: localizedUnit)
//min(max(0,localizedSpeed.value),150)
        return String(format: "%.0f", localizedSpeed.value )
    }
    
    private func isMetric() -> Bool {
        Locale.current.measurementSystem == .metric
    }
    
    private func getCountryName(for location: CLLocation) async {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return }
            var placeMarksArr = [String]()
            if let locality = placemark.locality {
                placeMarksArr.append(locality)
            }
            if let administrativeArea = placemark.administrativeArea {
                placeMarksArr.append(administrativeArea)
            }
            placeMarksArr.append(getTimeStamp())
            internalTownAndProvince = placeMarksArr.joined(separator: ", ")
            
        } catch {
            print("Error during revered geocoding: \(error)")
        }
    }
    
    private func getTimeStamp() -> String {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale.current
        let localizedTimestamp = dateFormatter.string(from: currentDate)
        return localizedTimestamp
    }
    
    private func getSpeedUnits(_ currentLocation: CLLocation) -> String {
        isMetric() ? "km/h" : "mph"
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error updating location: \(error.localizedDescription)")
    }
}
