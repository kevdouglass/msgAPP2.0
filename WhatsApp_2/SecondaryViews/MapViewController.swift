//
//  MapViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/24/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController{

    @IBOutlet weak var mapView: MKMapView!
    
    var location: CLLocation!
    
    // we are going to present our MapView in a Navigation controller
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.'
        self.title = "Map"
        setupUI()   // go to chat view controleler and check our didtapmessagebubleatindexpath for Maps/location
        openInMap()
    }
    
    //MARK: Set up Map View UI
    func setupUI() {
        var region = MKCoordinateRegion()
        region.center.longitude = location.coordinate.longitude
        region.center.latitude = location.coordinate.latitude
        
        // set the span
        region.span.latitudeDelta = 0.01
        region.span.longitudeDelta = 0.01
        
        mapView.setRegion(region, animated: false) // false so it doesnt zoom in to the place it will just show it
        mapView.showsUserLocation = true /// show blue dot over user current location
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation) /// drops a ping on our map
    }
    
    /// function that adds in the map
    
    
    //MARK: Open in "Maps"
    func createRightButton() {
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Open in Maps", style: .plain, target: self, action: #selector(self.openInMap))]
    }
    
    @objc func openInMap() {
        // once we create our button
        
        // get destination
        let regionDestination: CLLocationDistance = 10000   //10000 sq miles around destination
        
        let coordinates = location.coordinate
        
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDestination, longitudinalMeters: regionDestination)
        
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)    /// the 2 values are our option for user
        ]
        
        let placeMark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placeMark)
        mapItem.name = "User's Location"
        mapItem.openInMaps(launchOptions: options)
        
    }


}
