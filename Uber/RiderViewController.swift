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
    
    var uberHasCalled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let userEmail = Auth.auth().currentUser?.email {
            databaseRef.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded) { (DataSnapshot) in
                self.uberHasCalled = true
                self.callAnUberButton.setTitle("Cancel Uber", for: .normal)
            }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinates = manager.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
            userLocation = center
            
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
    
    @IBAction func logoutTapped(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            
            navigationController?.dismiss(animated: true, completion: nil)
        } catch {
            //Could not logout
        }
    }
    
    @IBAction func callAnUberTapped(_ sender: UIButton) {
        
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
