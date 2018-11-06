//
//  AcceptRequestViewController.swift
//  Uber
//
//  Created by Hector Mendoza on 11/5/18.
//  Copyright © 2018 Hector Mendoza. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class AcceptRequestViewController: UIViewController {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var requestButton: UIButton!
    
    var requestLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var driverEmail = ""
    var requestEmail = ""
    
    let databaseRef = Database.database().reference().child("RideRequests")
    
    var activeRequest = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        databaseRef.queryOrdered(byChild: "driverEmail").queryEqual(toValue: driverEmail).observeSingleEvent(of: .childAdded) { (snapshot) in
            self.activeRequest = true
            self.setRequestButtonState()
        }
        
        
        
        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        map.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = requestLocation
        annotation.title = requestEmail
        map.addAnnotation(annotation)
    }
    
    func setRequestButtonState() {
        if activeRequest {
            requestButton.setTitle("Cancel Request", for: .normal)
            
            navigationItem.hidesBackButton = true
        } else {
            requestButton.setTitle("Accept Request", for: .normal)
            navigationItem.hidesBackButton = false
        }
    }
    
    @IBAction func acceptTapped(_ sender: UIButton) {
        
        if activeRequest {
            //Cancel Request
            databaseRef.queryOrdered(byChild: "email").queryEqual(toValue: requestEmail).observeSingleEvent(of: .childAdded) { (snapshot) in
                snapshot.ref.child("driverEmail").removeValue()
                snapshot.ref.child("driverLat").removeValue()
                snapshot.ref.child("driverLon").removeValue()
            }
        } else {
            //Update the ride request
            databaseRef.queryOrdered(byChild: "email").queryEqual(toValue: requestEmail).observe(.childAdded) { (snapshot) in
                snapshot.ref.updateChildValues(["driverLat": self.driverLocation.latitude, "driverLon": self.driverLocation.longitude, "driverEmail": self.driverEmail])
                
                self.databaseRef.removeAllObservers()
            }
            
            //Give directions
            let requestCLLocation = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
            
            CLGeocoder().reverseGeocodeLocation(requestCLLocation) { (placemarks, error) in
                if let placemarks = placemarks {
                    
                    if placemarks.count > 0 {
                        let placeMark = MKPlacemark(placemark: placemarks[0])
                        let mapItem = MKMapItem(placemark: placeMark)
                        mapItem.name = self.requestEmail
                        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        mapItem.openInMaps(launchOptions: options)
                    }
                    
                }
            }
            
        }
        
        activeRequest = !activeRequest
        setRequestButtonState()
    }

}
