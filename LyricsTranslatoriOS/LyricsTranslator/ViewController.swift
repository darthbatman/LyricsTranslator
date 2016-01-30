//
//  ViewController.swift
//
//

import UIKit
import AVFoundation
import HealthKit
import Foundation
import CoreLocation
import WatchConnectivity
//dont have to uncletsocket

class ViewController: UIViewController, WCSessionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer? // Master layer where all the other stuff is layed on top of yerexcept this is on replcator layer
                                                    // whose idea was this
    
    
    let socket = SocketIOClient(socketURL: NSURL(string: "http://f19a3639.ngrok.io")!)
    
    @IBOutlet weak var songTextField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var label: UILabel!
    var heartRate = [String]()
    var session: WCSession!
    
    let healthKitStore:HKHealthStore = HKHealthStore()
    
    let lyricsLayer: CATextLayer = CATextLayer() // Displays lyrics
//    let speedLayer: CATextLayer = CATextLayer()
//    let stepsLayer: CATextLayer = CATextLayer()
//    let timerLayer: CATextLayer = CATextLayer()
//    let currentTimeLayer: CATextLayer = CATextLayer()
    
    let heightQuantity = HKQuantityType.quantityTypeForIdentifier(
        HKQuantityTypeIdentifierHeight)!
    
    let weightQuantity = HKQuantityType.quantityTypeForIdentifier(
        HKQuantityTypeIdentifierBodyMass)!
    
    let heartRateQuantity = HKQuantityType.quantityTypeForIdentifier(
        HKQuantityTypeIdentifierHeartRate)!
    
    let numOfSteps = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
    
    var totalSteps: Int = 0
    
    lazy var healthStore = HKHealthStore()
    
    /* The type of data that we wouldn't write into the health store */
    lazy var typesToShare: Set<HKSampleType> = {
        return [self.heightQuantity, self.weightQuantity]
    }()
    
    /* We want to read this type of data */
    lazy var typesToRead: Set<HKObjectType> = {
        return [self.heightQuantity, self.weightQuantity, self.heartRateQuantity, self.numOfSteps]
        
    }()
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        var receivedMSG = message["timer"] as! String
        let heartMSG = message["heartRate"] as! String
        
        print(String(receivedMSG))
        receivedMSG = String(receivedMSG)
        print("heart \(heartMSG)")
        
        
        
        if (receivedMSG == "Optional(\"start\")") {
            //start timer
            print("start")
            startTimer()
        } else if (receivedMSG == "Optional(\"stop\")") {
            //stop timer
            stopTimer()
        }
        
        
        //Use this to update the UI instantaneously (otherwise, takes a little while)
        dispatch_async(dispatch_get_main_queue()) {
//            self.textLayer.string = heartMSG
            self.heartRate.append(heartMSG)
            self.label.text = heartMSG
        }
    }
    
    var theTimer: NSTimer = NSTimer()
    
    func startTimer() {
        theTimer = NSTimer()
        
        timerCount = 0
//        timerLayer.foregroundColor = UIColor.greenColor().CGColor
//        timerLayer.string = "0:00"
        
        theTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateTimer", userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        //timerCount = 0
//        timerLayer.foregroundColor = UIColor(hue: 3, saturation: 3, brightness: 3, alpha: 0).CGColor
//        timerLayer.string = "0:80"
        theTimer.invalidate()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //previewLayer?.frame = self.view.bounds
        //previewLayer?.frame = cameraViewOne.layer.frame
        if HKHealthStore.isHealthDataAvailable(){
            
            healthStore.requestAuthorizationToShareTypes(typesToShare,
                readTypes: typesToRead,
                completion: {succeeded, error in
                    
                    if succeeded && error == nil{
                        print("Successfully received authorization")
                    } else {
                        if let theError = error{
                            print("Error occurred = \(theError)")
                        }
                    }
                    
            })
            
        } else {
            print("Health data is not available")
        }
    }
    
    var hour: Int = 0
    var minutes: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session.delegate = self;
            session.activateSession()
        }
        
        
        
        // try recording
//        record()
        
        
        
        startTimer()
        
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 1;
        self.locationManager.startUpdatingLocation()
        
        
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(NSCalendarUnit([.Hour, .Minute]), fromDate: date)
        hour = components.hour
        minutes = components.minute
        
        //print("Time: \(hour) : \(minutes)")
//        
//        if (minutes < 10) {
//            currentTimeLayer.string = "\(hour) : 0\(minutes)"
//        } else {
//            currentTimeLayer.string = "\(hour) : \(minutes)"
//        }
        
        
        
        self.refreshHealthData()
//        _ = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "refreshHealthData", userInfo: nil, repeats: true)
//        _ = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "clockUpdate", userInfo: nil, repeats: true)
        
        
        
    }
//    
//    func clockUpdate() {
//        let date = NSDate()
//        let calendar = NSCalendar.currentCalendar()
//        let components = calendar.components(NSCalendarUnit([.Hour, .Minute]), fromDate: date)
//        hour = components.hour
//        minutes = components.minute
//        
//        //print("Time: \(hour) : \(minutes)")
//        
////        if (minutes < 10) {
////            currentTimeLayer.string = "\(hour) : 0\(minutes)"
////        } else {
////            currentTimeLayer.string = "\(hour) : \(minutes)"
////        }
//        
//    }
    
    var timerCount: Int = 0
    
    func updateTimer() {
        timerCount++
//        var min = timerCount / 60
//        var sec = timerCount % 60
        
//        if (sec < 10) {
//            timerLayer.string = "\(min) : 0\(sec)"
//        } else {
//            timerLayer.string = "\(min) : \(sec)"
//        }
        
        
    }
    
    var oldSteps: Int = 0
    
    func refreshHealthData() {
        
        //print("refreshHealthData")
        
        //        let currentSpeed = locationManager.location?.speed
        //
        //        print(currentSpeed)
        //
        //        self.speedLayer.string = String(stringInterpolationSegment: currentSpeed)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
            ascending: false)
        
        let numOfStepsQuery = HKSampleQuery(sampleType: numOfSteps, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor], resultsHandler: {query, results, sample in
            guard let results = results where results.count > 0 else {
                //print("Could not read the user's bpm ")
                //print("or no bpm data was available")
                return
            }
            
            /* We only have one sample really */
            let sample = results[0] as! HKQuantitySample
            let numOfStepsCount = sample.quantity.doubleValueForUnit(HKUnit.countUnit())
            
            if (self.oldSteps == Int(numOfStepsCount)) {
                
            } else {
                self.totalSteps += Int(numOfStepsCount)
                self.oldSteps = Int(numOfStepsCount)
            }
            
            
            
            dispatch_async(dispatch_get_main_queue(), {
                
                /* Set the value of "KG" on the right hand side of the
                text field */
//                self.stepsLayer.string = "\(self.totalSteps) Steps"
                
                /* And finally set the text field's value to the user's
                weight */
                
            })
        })
        
        healthStore.executeQuery(numOfStepsQuery)
        
        //        let heartRateQuery = HKSampleQuery(sampleType: heartRateQuantity,
        //            predicate: nil,
        //            limit: 1,
        //            sortDescriptors: [sortDescriptor],
        //            resultsHandler: {query, results, sample in
        //
        //                guard let results = results where results.count > 0 else {
        //                    print("Could not read the user's bpm ")
        //                    print("or no bpm data was available")
        //                    return
        //                }
        //
        //                /* We only have one sample really */
        //                let sample = results[0] as! HKQuantitySample
        //                /* Get the weight in kilograms from the quantity */
        //                let heartRateInBPM = sample.quantity.doubleValueForUnit(HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit()))
        //
        //                /* This is the value of "KG", localized in user's language */
        //
        //                dispatch_async(dispatch_get_main_queue(), {
        //
        //                    /* Set the value of "KG" on the right hand side of the
        //                    text field */
        //                    self.textLayer.string = String(stringInterpolationSegment: heartRateInBPM)
        //
        //                    /* And finally set the text field's value to the user's
        //                    weight */
        //
        //                })
        //
        //        })
        //
        //        healthStore.executeQuery(heartRateQuery)
    }
    
//    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
//        print(newLocation)
//        
//        var distance: CLLocationDistance = newLocation.distanceFromLocation(oldLocation)
//        var timeDiff: NSTimeInterval = newLocation.timestamp.timeIntervalSinceDate(oldLocation.timestamp)
//        
//        var realSpeed = (distance / timeDiff) * 2.23693629
//        realSpeed = floor(realSpeed)
//        
//        let gpsSpeed: Double = newLocation.speed
//        print(realSpeed)
//        self.speedLayer.string = "Speed: \(realSpeed) mph"
//    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSessionPreset1920x1080
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let input = try! AVCaptureDeviceInput(device: backCamera)
        
        //var input = AVCaptureDeviceInput(device: backCamera, error: &error)
        var output: AVCaptureVideoDataOutput?
        
        if captureSession?.canAddInput(input) != nil {
            captureSession?.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            
            output = AVCaptureVideoDataOutput()
            
            if (captureSession?.canAddOutput(output) != nil) {
                
                //captureSession?.addOutput(stillImageOutput)
                captureSession?.addOutput(output)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
                previewLayer?.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
                //previewLayer?.frame = CGRect(self.view.bounds)
                
                let replicatorLayer = CAReplicatorLayer()
                //replicatorLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width / 2, self.view.bounds.size.height)
                replicatorLayer.frame = CGRectMake(0, 0, 400, 400)
                replicatorLayer.instanceCount = 2
                //replicatorLayer.instanceTransform = CATransform3DMakeTranslation(self.view.bounds.size.width / 2, 0.0, 0.0)
                replicatorLayer.instanceTransform = CATransform3DMakeTranslation(310, 0.0, 0.0)
                
                //replicatorLayer.instanceTransform = CATransform3DMakeTranslation(0.0, self.view.bounds.size.height / 2, 0.0)
                
                previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
                
                // setup the layer
                lyricsLayer.font = "Helvetica"
                lyricsLayer.fontSize = 13
                lyricsLayer.frame = CGRectMake(10, 120, 150, 150) // x, y, width, heights NOTE: THE LYRICSLAYER STARTS AT 0,0, BUT THE CAMERA VIEW IS LOWER THAN THIS
                lyricsLayer.alignmentMode = kCAAlignmentCenter
                lyricsLayer.string = "LyricsLyricsLyrics\n\n\nSample Text Sample text\n\n\n\nwhats up"
                lyricsLayer.foregroundColor = UIColor.whiteColor().CGColor
                
                previewLayer?.addSublayer(lyricsLayer)
                
                replicatorLayer.addSublayer(previewLayer!)
                
                self.view.layer.addSublayer(replicatorLayer)
                captureSession?.startRunning()
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Record the user's speech
    //declare instance variable
    var audioRecorder:AVAudioRecorder!
    
    
    // records and requests api.ai
    func record() {
        
        // test
//        sendGetRequest()
        
        //init
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        
        //ask for permission
        if (audioSession.respondsToSelector("requestRecordPermission:")) {
            
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("RECORDING! OILY OILY")
                    
                    //set category and activate recorder session
                    try! audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                    try! audioSession.setActive(true)
                    
                    
                    //get documnets directory
                    let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                    let fullPath = documentsDirectory.stringByAppendingString("voiceRecording.caf")

                    let url = NSURL.fileURLWithPath(fullPath)
                    
                    //create AnyObject of settings
                    let settings: [String : AnyObject] = [
                        AVFormatIDKey:Int(kAudioFormatAppleIMA4), //Int required in Swift2
                        AVSampleRateKey:44100.0,
                        AVNumberOfChannelsKey:2,
                        AVEncoderBitRateKey:12800,
                        AVLinearPCMBitDepthKey:16,
                        AVEncoderAudioQualityKey:AVAudioQuality.Max.rawValue
                    ]
                    
                    //record
                    try! self.audioRecorder = AVAudioRecorder(URL: url, settings: settings)
                    
                    // send an http post request to the voice recognition api
                    let request = NSMutableURLRequest(URL: NSURL(string: "https://api.api.ai/v1/query?v=20150910")!)
                    
                    // format the request
                    request.HTTPMethod = "POST"
                    
                    request.addValue("5bd76f3b-b0e2-438f-a093-0c2e681a92dd", forHTTPHeaderField: "ocp-apim-subscription-key")
                    request.addValue("Bearer 2b725cdd533242e6b7df34688803bc1d ", forHTTPHeaderField: "Authorization")
                    request.addValue("application/json", forHTTPHeaderField: "Content-type")
                    
                    request.addValue(url.absoluteString, forHTTPHeaderField: "voiceData")
                    
//                    let postString = "id=13&name=Jack"
//                    request.HTTPBody = url
                    
                    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                        guard error == nil && data != nil else {                                                          // check for fundamental networking error
                            print("error=\(error)")
                            return
                        }
                        
                        if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {           // check for http errors
                            print("statusCode should be 200, but is \(httpStatus.statusCode)")
                            print("response = \(response)")
                        }
                        
                        let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                        print("responseString = \(responseString)")
                    }
                    task.resume()

                    
                } else{
                    print("NOT RECORDING not granted")
                }
            })
        } // end of if has permission? idk who cares
    
    } // end of record function
    
//    func sendGetRequest() {
//        let url = NSURL(string: "http://www.stackoverflow.com")
//        
//        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
//            print(NSString(data: data!, encoding: NSUTF8StringEncoding))
//        }
//        
//        task.resume()
//
//    } // end of sendGetRequest()

}