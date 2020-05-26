//
//  ViewController.swift
//  API_2_0521
//
//  Created by mmslab-mini on 2020/5/21.
//  Copyright © 2020 mmslab-mini. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import Toast

class ViewController: UIViewController {
    @IBOutlet var StartingPoint: UITextField!
    @IBOutlet var Destination: UITextField!
    @IBOutlet var StationDisplayTable: UITableView!
    
    //var stationTableArr : Results<stationTable>?
    //let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //stationTableArr = realm.objects(stationTable.self)
        //print(realm.configuration.fileURL!.deletingLastPathComponent().path)
        
    }
    
    @IBOutlet var mapView: MKMapView!
    static var location:CLLocationManager? = nil
    // Show current location
    @IBAction func CurrentLocation(_ sender: Any) {
        if(ViewController.location == nil){
            ViewController.location = CLLocationManager()
            ViewController.location?.requestWhenInUseAuthorization()
            ViewController.location?.startUpdatingLocation()
        }
        mapView.setCenter(mapView.userLocation.coordinate, animated: true)
    }
    
    
    
    
}

class stationTable: Object{
    @objc dynamic var station = ""
    @objc dynamic var location = ""
    @objc dynamic var positionLat = 0.0   //coordinates
    @objc dynamic var positionLon = 0.0   //coordinates
}