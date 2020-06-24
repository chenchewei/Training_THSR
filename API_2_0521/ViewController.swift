//
//  ViewController.swift
//  API_2_0521
//
//  Created by mmslab-mini on 2020/5/21.
//  Copyright © 2020 mmslab-mini. All rights reserved.
//

import UIKit
import MapKit
import Toast
import Foundation
import CommonCrypto

/********************** PTX Auth key from sample code ******************************/
enum CryptoAlgorithm {  //列舉
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    var HMACAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:      result = kCCHmacAlgMD5
        case .SHA1:     result = kCCHmacAlgSHA1
        case .SHA224:   result = kCCHmacAlgSHA224
        case .SHA256:   result = kCCHmacAlgSHA256
        case .SHA384:   result = kCCHmacAlgSHA384
        case .SHA512:   result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .MD5:      result = CC_MD5_DIGEST_LENGTH
        case .SHA1:     result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:   result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:   result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:   result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}
extension String {
    func hmac(algorithm: CryptoAlgorithm, key: String) -> String {
        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = self.cString(using: String.Encoding.utf8)
        let digestLen = algorithm.digestLength
        var result = [CUnsignedChar](repeating: 0, count: digestLen)
        CCHmac(algorithm.HMACAlgorithm, cKey!, strlen(cKey!), cData!, strlen(cData!), &result)
        let hmacData:Data = Data(bytes: result, count: digestLen)
        let hmacBase64 = hmacData.base64EncodedString(options: .lineLength64Characters)
        return String(hmacBase64)
    }
}
func getServerTime() -> String {
    let dateFormater = DateFormatter()
    dateFormater.dateFormat = "EEE, dd MMM yyyy HH:mm:ww zzz"
    dateFormater.locale = Locale(identifier: "en_US")
    dateFormater.timeZone = TimeZone(secondsFromGMT: 0)
    return dateFormater.string(from: Date())
}
let APIUrl = "https://ptx.transportdata.tw/MOTC/v2/Rail/THSR/Station?$top=30&$format=JSON";
let APP_ID = "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"
let APP_KEY = "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"
let xdate : String = getServerTime();
let signDate = "x-date: " + xdate;
let base64HmacStr = signDate.hmac(algorithm: .SHA1, key: APP_KEY)
let authorization:String = "hmac username=\""+APP_ID+"\", algorithm=\"hmac-sha1\", headers=\"x-date\", signature=\""+base64HmacStr+"\""
/*******************************************************************************/
/* API datas*/
public class Station {
    var StationName = ""
    var StationAddress = ""
    var StationID = ""
    var StationPositionLat = Double()
    var StationPositionLon = Double()
}
/* Return coodinates from StationViewController */
public class StationReturnValue {
    var ReturnLat = Double()
    var ReturnLon = Double()
    var ReturnFlag = false
}


class ViewController: UIViewController,MKMapViewDelegate {
    
    @IBOutlet var StartingPoint: UITextField!
    @IBOutlet var Destination: UITextField!
    @IBOutlet var mapView: MKMapView!
    
    var StationData = [PTX]()
    var SearchList = [Station]()
    var StationRE : StationReturnValue!    // return values
    
    var TimeTableStartID = ""
    var TimeTableDesID = ""
    
    /* THSR */
    var THSRdata = [THSRModel]()
    var TimeTableList = [THSRDetail]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getDataFromAPI()
        mapView.delegate = self
        StationRE = StationReturnValue()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        ReturnValueActions()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let StationVC = segue.destination as! StationViewController
        StationVC.StationRE = StationRE
        StationVC.delegate = self
    }

    /* Environments set up */
    func getDataFromAPI() {
        let url = URL(string: APIUrl)
        var request = URLRequest(url: url!)
        request.setValue(xdate, forHTTPHeaderField: "x-date")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        let task = URLSession.shared.dataTask(with: request){ data, response,error in
        do {
            var StationList = [Station]()
            self.StationData = try JSONDecoder().decode([PTX].self, from: data!)
                        
            for i in 0..<self.StationData.count {
                let station = Station()
                station.StationID = self.StationData[i].StationID
                station.StationName = self.StationData[i].StationName?.Zh_tw ?? ""
                station.StationAddress = self.StationData[i].StationAddress
                station.StationPositionLat = self.StationData[i].StationPosition?.PositionLat ?? 0.0
                station.StationPositionLon = self.StationData[i].StationPosition?.PositionLon ?? 0.0
                StationList.append(station)
                self.SearchList = StationList   //throw datas
                /* Station pins */
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(StationList[i].StationPositionLat, StationList[i].StationPositionLon)
                annotation.title = StationList[i].StationName
                annotation.subtitle = StationList[i].StationID  //StationAddress
                self.mapView.addAnnotation(annotation)
                }
            }
        catch {
            print(error)
            }
        }
        task.resume()
    }
    /* Show current location */
    static var location:CLLocationManager? = nil
    @IBAction func CurrentLocation(_ sender: Any) {
        if(ViewController.location == nil){
            ViewController.location = CLLocationManager()
            ViewController.location?.requestWhenInUseAuthorization()
            ViewController.location?.startUpdatingLocation()
        }
        mapView.setCenter(mapView.userLocation.coordinate, animated: true)
    }
   /* Switch Text */
    @IBAction func switchText(_ sender: Any) {
        if(StartingPoint.text != Destination.text){
            let temp = StartingPoint.text
            StartingPoint.text = Destination.text
            Destination.text = temp
        }
        else{
            view.makeToast("Starting point and destination should be different.")
        }
    }
    /* Tap and show alert view */
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
        let ann = view.annotation?.title
        let SelectedID = view.annotation?.subtitle
        
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let RestaurantVC = storyboard.instantiateViewController(withIdentifier:"Restaurant") as! RestaurantViewController
        
        let alertController = UIAlertController(title: "選擇動作", message: "", preferredStyle: .alert)
        let StartAction = UIAlertAction(title: "設成起點", style: .default,handler:{ (action) in
            self.StartingPoint.text = ann!!
            self.TimeTableStartID = SelectedID!!})
        let DestAction = UIAlertAction(title: "設成終點", style: .default,handler:{ (action) in
            self.Destination.text = ann!!
            self.TimeTableDesID = SelectedID!!
            self.getTHSRDatas()
        })
        let RestAction = UIAlertAction(title: "附近餐廳", style: .default,handler:{ (action) in self.navigationController?.pushViewController(RestaurantVC, animated: true)})
        let CancelAction = UIAlertAction(title: "取消", style: .cancel)
        alertController.addAction(StartAction)
        alertController.addAction(DestAction)
        alertController.addAction(RestAction)
        alertController.addAction(CancelAction)
        present(alertController, animated: true)
    }
    /* Making sure station texts arent blank before segue */
    @IBAction func CheckText(_ sender: Any) {
        if(StartingPoint.text == Destination.text){
            view.makeToast("Starting point and destination should be different.")
        }
        else if(StartingPoint.text == "" || Destination.text == ""){
            view.makeToast("Starting point and destination cannot be blank.")
        }
        else{
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let TimeTableVC = storyboard.instantiateViewController(withIdentifier:"Timetable") as! TimeTableViewController
            
            TimeTableVC.StartName = StartingPoint.text ?? ""
            TimeTableVC.DesName = Destination.text ?? ""
            TimeTableVC.xdate = xdate
            TimeTableVC.authorization = authorization
            
            TimeTableVC.TimeTableList = TimeTableList

            self.navigationController?.pushViewController(TimeTableVC, animated: true)
        }
    }
    func getTHSRDatas() {
        let Todaydate : String = getTime();
        let TimeTableURL = "https://ptx.transportdata.tw/MOTC/v2/Rail/THSR/DailyTimetable/OD/"+TimeTableStartID+"/to/"+TimeTableDesID+"/"+Todaydate+"?$top=30&$format=JSON"
        let url = URL(string: TimeTableURL)
        var request = URLRequest(url: url!)
        request.setValue(xdate, forHTTPHeaderField: "x-date")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        URLSession.shared.dataTask(with: request){ data, response,error in do {
            var TempList = [THSRDetail]()
            self.THSRdata = try JSONDecoder().decode([THSRModel].self, from: data!)
            for i in 0..<self.THSRdata.count {
                let timeTable = THSRDetail()
                if(self.THSRdata[i].DailyTrainInfo?.Direction == 0) {
                    timeTable.Direction = "南下"
                }
                else{
                    timeTable.Direction = "北上"
                    }
                timeTable.TrainNo = self.THSRdata[i].DailyTrainInfo?.TrainNo ?? ""
                timeTable.DepartureTime = self.THSRdata[i].OriginStopTime?.ArrivalTime ?? ""
                timeTable.ArrivalTime = self.THSRdata[i].DestinationStopTime?.ArrivalTime ?? ""
                TempList.append(timeTable)
                self.TimeTableList = TempList
                }
            }
        catch {
            print(error.localizedDescription)
            }
        }.resume()
    }
    func getTime() -> String {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd"
        return dateFormater.string(from: Date())
    }
    /* Jump to StationViewController */
    @IBAction func StationClicked(_ sender: Any) {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let StationVC = storyboard.instantiateViewController(withIdentifier:"Station") as! StationViewController
        StationVC.StationList = SearchList
        StationVC.delegate = self
        self.navigationController?.pushViewController(StationVC, animated: true)
    }
    /* Return values */
    func ReturnValueActions() {
        if(StationRE.ReturnFlag){
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let center = CLLocationCoordinate2D(latitude: StationRE.ReturnLat, longitude: StationRE.ReturnLon)
            let region = MKCoordinateRegion(center: center , span: span)
            mapView.setRegion(region, animated:true)
            StationRE.ReturnFlag = false
        }
    }
}

extension ViewController: StationReturnDelegate {
    func sendStationCoordinates(sentData: StationReturnValue){
        StationRE = sentData
    }
}
