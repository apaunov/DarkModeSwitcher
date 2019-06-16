//
//  StatusMenuController.swift
//  DarkModeSwitcher
//
//  Created by Andrey Paunov on 2019-06-09.
//  Copyright © 2019 Andrey Paunov. All rights reserved.
//

import Cocoa
import Solar
import CoreLocation

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    let locationManager = CLLocationManager()
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    var source = ""
    var isLoaded = false
    
    override func awakeFromNib() {
        let icon = NSImage(named: "DarkModeSwitcher")
        icon?.isTemplate = true
        
        statusItem.button?.image = icon
        statusItem.menu = statusMenu
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    // HELPER FUNCTIONS
    @objc private func dayState(coordinate: CLLocationCoordinate2D) {
        let solar = Solar(coordinate: coordinate)
        
        guard let sunrise = solar?.sunrise else {
            return
        }
        
        guard let sunset = solar?.sunset else {
            return
        }
        
        let currentDate = Date()
        
        if sunset < currentDate && currentDate < sunrise {
            // Dark mode
            let timeUntilSunrise = sunrise.timeIntervalSince(currentDate)
            toggleDarkMode(isDarkMode: true)
            perform(#selector(dayState(coordinate:)), with: coordinate, afterDelay: timeUntilSunrise)
        } else {
            // Light mode
            let timeUntilSunset = sunset.timeIntervalSince(currentDate)
            toggleDarkMode(isDarkMode: false)
            perform(#selector(dayState(coordinate:)), with: coordinate, afterDelay: timeUntilSunset)
        }
    }
    
    private func toggleDarkMode(isDarkMode: Bool) {
        source = """
            tell application "System Events"
                tell appearance preferences
                    set dark mode to \(isDarkMode)
                end tell
            end tell
        """
        
        let script = NSAppleScript(source: source)
        var error: NSDictionary? = [:]
        
        script?.executeAndReturnError(&error)
    }
}

extension StatusMenuController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations.last
        
        guard let coordinate = currentLocation?.coordinate else {
            return
        }

        if (!isLoaded) {
            isLoaded = true
            
            dayState(coordinate: coordinate)
        }
    }
}
