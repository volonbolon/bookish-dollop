//
//  MapViewViewController.swift
//  BookishDollop
//
//  Created by Ariel Rodriguez on 16/02/2018.
//  Copyright © 2018 Ariel Rodriguez. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MapViewViewController: UIViewController {
    var location: String?
    // MARK: - Privates
    private var geocoder = CLGeocoder()

    // MARK: - IBOutlets
    @IBOutlet var mapView: MKMapView!

    // Nasty hack. Perhaps an NSOperation encapsulating the call would be better.
    // And much better would be some sort of API that allows bath geo locations.
    // I will investigate MapQuest and Google.
    private func geoLocateLocations() {
        guard let locationString = self.location else {
            return
        }
        let string = "\(locationString), San Francisco, California"
        geocoder.geocodeAddressString(string) { [unowned self] (placemarks: [CLPlacemark]?, error: Error?) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let placemark = placemarks?.first else {
                return
            }
            guard let coordinate = placemark.location?.coordinate else {
                return
            }

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = string

            self.mapView.addAnnotation(annotation)

            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.geoLocateLocations()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension MapViewViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "identifier") as? MKPinAnnotationView
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "identifier")
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .infoLight)
        } else {
            annotationView?.annotation = annotation
        }

        return annotationView
    }
}
