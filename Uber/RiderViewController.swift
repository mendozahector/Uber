//
//  RiderViewController.swift
//  Uber
//
//  Created by Hector Mendoza on 11/2/18.
//  Copyright © 2018 Hector Mendoza. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import FirebaseDatabase

class RiderViewController: UIViewController, CLLocationManagerDelegate {
    
    let databaseRef: DatabaseReference! = Database.database().reference()
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var callAnUberButton: UIButton!
    
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var driverOnTheWay = false
    
    var uberHasCalled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let userEmail = Auth.auth().currentUser?.email {
            databaseRef.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded) { (snapshot) in
                self.uberHasCalled = true
                self.callAnUberButton.setTitle("Cancel Uber", for: .normal)
                
                if let rideRequestDictionary = snapshot.value as? [String: AnyObject] {
                    if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                        if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                            self.driverOnTheWay = true
                            self.displayDriverAndRider()
                            
                            let driverEmail = rideRequestDictionary["driverEmail"] as! String
                            self.updateDriverLocation(email: driverEmail)
                            
                        }
                    }
                }
                
            }
        }
        
    }
    
    func updateDriverLocation(email: String) {
        databaseRef.child("RideRequests").queryOrdered(byChild: "driverEmail").queryEqual(toValue: email).observe(.childChanged) { (snapshot) in
            
            if let rideRequestDictionary = snapshot.value as? [String: AnyObject] {
                if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                    if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                        self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                        self.displayDriverAndRider()
                    }
                }
            }
            
        }
        
    }
    
    func displayDriverAndRider() {
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        //Meters to Kilometers
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        //Rounded Kilometers to Miles
        let roundedDistance = round((distance * 0.621371) * 100) / 100
        
        callAnUberButton.setTitle("You driver is \(roundedDistance) miles away!", for: .normal)
        map.removeAnnotations(map.annotations)
        
        let latDelta = abs(driverLocation.latitude - userLocation.latitude) * 2 + 0.005
        let lonDelta = abs(driverLocation.longitude - userLocation.longitude) * 2 + 0.005
        
        let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        map.setRegion(region, animated: true)
        
        let riderAnnotation = MKPointAnnotation()
        riderAnnotation.coordinate = userLocation
        riderAnnotation.title = "Your Location"
        
        let driverAnnotation = MKPointAnnotation()
        driverAnnotation.coordinate = driverLocation
        driverAnnotation.title = "Your Driver"
        
        map.addAnnotations([riderAnnotation, driverAnnotation])
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinates = manager.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
            userLocation = center
            
            if uberHasCalled {
                displayDriverAndRider()
            } else {
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                
                map.setRegion(region, animated: true)
                
                //Remove previous annotations
                map.removeAnnotations(map.annotations)
                
                //Add current location annotation
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                annotation.title = "Your location"
                map.addAnnotation(annotation)
            }
            
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
    
    @IBAction func callAnUberTapped(_ sender: UIButton) {
        if !driverOnTheWay {
        
            if let userEmail = Auth.auth().currentUser?.email {
                
                databaseRef.child("RideResquests").removeAllObservers()
                
                if uberHasCalled == false {
                    let rideRequestsDictionary: [String: Any] = ["email": userEmail, "lat": userLocation.latitude, "lon": userLocation.longitude]
                    
                    databaseRef.child("RideRequests").childByAutoId().setValue(rideRequestsDictionary)
                    
                    uberHasCalled = true
                    
                    callAnUberButton.setTitle("Cancel Uber", for: .normal)
                } else {
                    databaseRef.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded) { (DataSnapshot) in
                        DataSnapshot.ref.removeValue()
                    }
                    
                    uberHasCalled = false
                    callAnUberButton.setTitle("Call Uber", for: .normal)
                }
                
            }
            
        }
    }
    
}
