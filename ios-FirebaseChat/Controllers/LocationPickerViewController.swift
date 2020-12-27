//
//  LocationPickerViewController.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/12/26.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    private var coordinates: CLLocationCoordinate2D?
    private var isPickable = true  // 判斷是否要出現 Sender Button
    
    private let map: MKMapView = {
        let map = MKMapView()
        
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        super.init(nibName: nil, bundle: nil)
        self.coordinates = coordinates
        self.isPickable = coordinates == nil // if (coordinates != nil) just show location
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Location"
        view.backgroundColor = .systemBackground
        
        // add Send UIBarButtonItem
        if isPickable{
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
            
            // user tap the map
            let tap = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            tap.numberOfTouchesRequired = 1  // 幾根指頭觸發
            tap.numberOfTapsRequired = 1  // 點一下會觸發
            
            map.isUserInteractionEnabled = true
            map.addGestureRecognizer(tap)
        }else{
            // just show location
            // add pin
            guard let coordinates = coordinates else {
                return
            }
            
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        
        view.addSubview(map)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
        
    }
    
    @objc func sendButtonTapped(){
        guard let coordinates = coordinates else {
            return
        }
        completion?(coordinates)
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc func didTapMap(_ tap: UITapGestureRecognizer){
        let locationInView = tap.location(in: map)
        // point: 要轉換的點 view: point參數參考坐標系的視圖
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)  // 將指定view的坐標的轉換為map坐標
        self.coordinates = coordinates
        
        // remove all pins
        for annotation in map.annotations{
            map.removeAnnotation(annotation)
        }
        
        // 標註
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
}
