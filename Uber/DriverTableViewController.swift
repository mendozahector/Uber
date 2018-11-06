//
//  DriverTableViewController.swift
//  Uber
//
//  Created by Hector Mendoza on 11/3/18.
//  Copyright © 2018 Hector Mendoza. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class DriverTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    let databaseRef: DatabaseReference! = Database.database().reference()
    
    var rideRequests: [DataSnapshot] = []
    var locationManager = CLLocationManager()
    var driverLocation = CLLocationCoordinate2D()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        databaseRef.child("RideRequests").observe(.childAdded) { (snapshot) in
            if let rideRequestDictionary = snapshot.value as? [String: AnyObject] {
                
                if let driverEmail = rideRequestDictionary["driverEmail"] as? String {
                    if driverEmail == Auth.auth().currentUser?.email {
                        self.performSegue(withIdentifier: "requestSegue", sender: snapshot)
                    }
                } else {
                    self.rideRequests.append(snapshot)
                    self.tableView.reloadData()
                }
                
            }
            
        }
        
        databaseRef.child("RideRequests").observe(.childChanged) { (snapshot) in
            var dataExists = false
            
            for index in 0..<self.rideRequests.count {
                if self.rideRequests[index].key == snapshot.key {
                    dataExists = true
                    self.rideRequests[index] = snapshot
                    self.tableView.reloadData()
                    break
                }
            }
            
            if !dataExists {
                self.rideRequests.append(snapshot)
                self.tableView.reloadData()
            }
            
        }
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            self.tableView.reloadData()
        }
        
    }
    
    @IBAction func logoutTapped(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            
            navigationController?.dismiss(animated: true, completion: nil)
        } catch {
            //Could not logout
        }
    }
    
    //MARK: - Getting Driver's location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate {
            driverLocation = coordinate
        }
    }
    

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rideRequests.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rideRequestCell", for: indexPath)
        
        let snapshot = rideRequests[indexPath.row]
        
        if let rideRequestDictionary = snapshot.value as? [String: AnyObject] {
            
            if let email = rideRequestDictionary["email"] as? String {
                if let lat = rideRequestDictionary["lat"] as? Double {
                    if let lon = rideRequestDictionary["lon"] as? Double {
                        
                        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                        let riderCLLocation = CLLocation(latitude: lat, longitude: lon)
                        
                        //Meters to Kilometers
                        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
                        //Rounded Kilometers to Miles
                        let roundedDistance = round((distance * 0.621371) * 100) / 100
                        
                        cell.textLabel?.text = "\(email) - \(roundedDistance) miles away."
                    }
                }
            }
            
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let snapshot = rideRequests[indexPath.row]
        performSegue(withIdentifier: "requestSegue", sender: snapshot)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? AcceptRequestViewController {
            
            if let snapshot = sender as? DataSnapshot {
                
                if let rideRequestDictionary = snapshot.value as? [String: AnyObject] {
                    
                    if let email = rideRequestDictionary["email"] as? String {
                        if let lat = rideRequestDictionary["lat"] as? Double {
                            if let lon = rideRequestDictionary["lon"] as? Double {
                                
                                let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                
                                destinationVC.requestEmail = email
                                destinationVC.requestLocation = location
                                destinationVC.driverLocation = driverLocation
                                destinationVC.driverEmail = (Auth.auth().currentUser?.email)!
                            }
                        }
                    }
                    
                }
                
            }
            
        }
    }
    

}
