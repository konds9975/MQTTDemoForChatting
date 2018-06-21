//
//  AppDelegate.swift
//  MQTTDemoForChatting
//
//  Created by Inkswipe on 6/7/18.
//  Copyright © 2018 Fortune4 Technologies. All rights reserved.
//

//# Uncomment the next line to define a global platform for your project
//    # platform :ios, '9.0'
//
//    target 'MQTTDemoForChatting' do
//# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
//use_frameworks!
//
//pod 'Moscapsule', :git => 'https://github.com/flightonary/Moscapsule.git'
//pod 'OpenSSL-Universal'
//
//# Pods for MQTTDemoForChatting
//
//    target 'MQTTDemoForChattingTests' do
//inherit! :search_paths
//# Pods for testing
//    end
//
//    target 'MQTTDemoForChattingUITests' do
//inherit! :search_paths
//# Pods for testing
//    end
//
//end
import Moscapsule
import UIKit
import CoreData
import UserNotifications
import SDWebImage
import IQKeyboardManagerSwift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        DBManager.shared.realmDataBaseSetup()
        UNUserNotificationCenter.current().requestAuthorization(options: [[.alert, .sound, .badge]], completionHandler: { (granted, error) in
            // Handle Error
        })
        UNUserNotificationCenter.current().delegate = self
        
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(
            1)
        setUpIQKeyboradManager()
        return true
    }
    func setUpIQKeyboradManager()
    {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.previousNextDisplayMode = .alwaysHide
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.shouldShowToolbarPlaceholder = false
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
     
        print("performFetchWithCompletionHandler")
        
        let mqttConfig = MQTTConfig(clientId: "ios", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        mqttConfig.onMessageCallback = { meaage in
            if meaage.topic == "fabit/user/1" {
                print("MQTT Message received: payload=\(String(describing: meaage.payloadString))")
                DispatchQueue.main.sync {
                    self.sendNotification()
                    //completionHandler(UIBackgroundFetchResult.newData)

                }
            }
            else
            {
                print("MQTT Message received: payload=\(String(describing: meaage.payloadString))")
                //completionHandler(UIBackgroundFetchResult.newData)
            }

        }
        let mqttClient = MQTT.newConnection(mqttConfig)
        mqttClient.subscribe("fabit/user/1", qos: 0)
    }
    func startBackgroundTask() {
        let application = UIApplication.shared
        BackgroundTask.run(application: application) { backgroundTask in
            print("end")
             UIApplication.shared.applicationIconBadgeNumber = 100
            backgroundTask.end()
        }
         UIApplication.shared.applicationIconBadgeNumber = 0
        print("begin")
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .sound])
    }
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

//    func applicationDidEnterBackground(_ application: UIApplication) {
//        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
//        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//
//       // Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
//       // startBackgroundTask()
//    }
    var bgTask : UIBackgroundTaskIdentifier!
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Create a pseudo background task to system call applicationWillTerminate when app enter background
        // Default system will not call applicationWillTerminate when app enter background
        // applicationWillTerminate only called when user close app in app switcher or some special cases of system
       
    }
  
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Meeting Reminder"
        content.subtitle = "messageSubtitle"
        content.body = "Don't forget to bring coffee."
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
                                                        repeats: false)
        let requestIdentifier = "demoNotification"
        let request = UNNotificationRequest(identifier: requestIdentifier,
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request,
                                               withCompletionHandler: { (error) in
                                                // Handle error
        })
    }
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    var counter = 0;
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
        //Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        startBackgroundTask()
        self.saveContext()
    }

    @objc func timerAction() {
        counter += 1
        UIApplication.shared.applicationIconBadgeNumber = counter
    }
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "MQTTDemoForChatting")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}





/*
 
 //
 //  WebHandler.swift
 //  TripGroupTrack
 //
 //  Created by Geetanjali on 14/01/17.
 //  Copyright © 2017 Geetanjali. All rights reserved.
 //
 
 import UIKit
 import Foundation
 
 @objc protocol WebHandlerDelegate
 {
 func APIResponseArrived(_ Response:AnyObject, error : String , number : String)
 
 //@objc optional func uploadImageResponse(_ Response:AnyObject, error : String , number : String)
 }
 class WebHandler: NSObject
 {
 var reachability : Reachability! = nil
 var delegate:WebHandlerDelegate! = nil
 
 func doRequestGet(urlStr : String ,number : String)
 {
 DispatchQueue.global(qos: .background).async {
 
 
 let urlStr = urlStr.replacingOccurrences(of: " ", with: "%20")
 self.reachability = Reachability()
 
 if self.reachability!.isReachable
 {
 // print("Internet is Available ")
 
 // Show MBProgressHUD Here
 var config:URLSessionConfiguration!
 var urlSession:URLSession!
 
 config = URLSessionConfiguration.default
 urlSession = URLSession(configuration: config)
 
 // MARK:- HeaderField
 let HTTPHeaderField_ContentType = "Content-Type"
 
 // MARK:- ContentType
 let ContentType_ApplicationJson = "application/json"
 
 //MARK: HTTPMethod
 let HTTPMethod_Get = "GET"
 
 let callURL = URL.init(string: urlStr as String)
 
 var request = URLRequest.init(url: callURL!)
 
 request.timeoutInterval = 120.0 // TimeoutInterval in Second
 request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
 request.addValue(ContentType_ApplicationJson, forHTTPHeaderField: HTTPHeaderField_ContentType)
 request.httpMethod = HTTPMethod_Get
 
 let dataTask = urlSession.dataTask(with: request)
 { (data,response,error) in
 if error != nil
 {
 //return
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0" ,number : number)
 }
 do
 {
 if data != nil
 {
 let resultJson = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
 
 // print("Result",resultJson!)
 self.delegate.APIResponseArrived(resultJson as AnyObject , error: "1",number : number)
 }
 else
 {
 // print("somthing went worng")
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0",number : number)
 //self.delegate.somthingWentWorng(error:"Somthing Went Worng")
 }
 }
 catch
 {
 print("Error -> \(error)")
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 self.delegate.APIResponseArrived([] as AnyObject , error: "0",number : number)
 }
 }
 
 dataTask.resume()
 }
 else
 {
 Constant.shared.hideIndicator()
 // print("Internet is NOT Available")
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.kMessageNoInternetConnection)
 
 }
 
 }
 
 }
 
 func doRequestPost(parameters : AnyObject, urlStr : String ,number : String)
 {
 let urlStr = urlStr.replacingOccurrences(of: " ", with: "%20")
 reachability = Reachability()
 
 if reachability!.isReachable
 {
 print("HTTPURL   " + (urlStr as String))
 //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
 
 //        let parameters = ["email": "manojrkhole@gmail.com", "password": "qwerty"] as Dictionary<String, String>
 
 //create the url with URL
 let url = URL(string: urlStr as String)! //change the url
 
 //create the session object
 let session = URLSession.shared
 
 //now create the URLRequest object using the url object
 var request = URLRequest(url: url)
 
 request.httpMethod = "POST" //set http method as POST
 request.timeoutInterval = 120.0
 do
 {
 request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
 
 }
 catch let error
 {
 print(error.localizedDescription)
 }
 request.addValue("application/json", forHTTPHeaderField: "Content-Type")
 request.addValue("application/json", forHTTPHeaderField: "Accept")
 //request.addValue(Constant.shared.getApiTokan() , forHTTPHeaderField: "X-CSRF-Token")
 //create dataTask using the session object to send data to the server
 let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
 
 guard error == nil else
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0",number:  number)
 return
 
 }
 
 guard let data = data else
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 
 self.delegate.APIResponseArrived([] as AnyObject, error: "0",number: number)
 return
 
 }
 
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
 {
 // print(json)
 // handle json...
 self.delegate.APIResponseArrived(json as AnyObject, error: "1",number:  number)
 //  self.delegate.API(jsonDic: json as NSDictionary)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1",number:  number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
 print(dataString as Any)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0",number: number)
 }
 })
 task.resume()
 
 }
 else
 {
 // print("Internet is NOT Available")
 Constant.shared.hideIndicator()
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.kMessageNoInternetConnection)
 }
 
 }
 func uploadImagewith(parameters:Dictionary<String, String>,urlStr : String ,imageName : String , image : UIImage? ,videoName : String, videoURL : URL? , number:String)
 {
 
 let urlStr = urlStr.replacingOccurrences(of: " ", with: "%20")
 reachability = Reachability()
 
 if reachability!.isReachable
 {
 if let actualImage = image
 {
 
 if let videoUrl = videoURL
 {
 
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 let image_data = UIImageJPEGRepresentation(actualImage, 0.0) //UIImagePNGRepresentation(profileImage.image!)
 
 if(image_data == nil)
 {
 return
 }
 let body = NSMutableData()
 let fname = "test.jpg"
 let mimetype = "image/jpeg"
 
 do{
 
 let videoData = try Data(contentsOf: videoUrl)
 let vfname = "test.mp4"
 let vmimetype = "video/mp4"
 
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(imageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(image_data!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(videoName)\"; filename=\"\(vfname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(vmimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(videoData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 request.httpBody = body as Data
 _ = URLSession.shared
 } catch let error {
 print(error)
 
 }
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 else
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 let image_data = UIImageJPEGRepresentation(actualImage, 0.0) //UIImagePNGRepresentation(profileImage.image!)
 
 if(image_data == nil)
 {
 return
 }
 let body = NSMutableData()
 let fname = "test.jpg"
 let mimetype = "image/jpeg"
 
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(imageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(image_data!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 request.httpBody = body as Data
 _ = URLSession.shared
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 }
 else if let videoUrl = videoURL
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 do {
 
 
 let videoData = try Data(contentsOf: videoUrl)
 let body = NSMutableData()
 let fname = "test.mp4"
 let mimetype = "video/mp4"
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(videoName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(videoData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 request.httpBody = body as Data
 _ = URLSession.shared
 } catch let error {
 print(error)
 
 }
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 else
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 let body = NSMutableData()
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 request.httpBody = body as Data
 _ = URLSession.shared
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 }
 else
 {
 // print("Internet is NOT Available")
 Constant.shared.hideIndicator()
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.kMessageNoInternetConnection)
 }
 }
 func uploadVideowith(parameters:Dictionary<String, String>,urlStr : String ,videoName : String , videoUrl : URL,number:String)
 {
 
 let urlStr = urlStr.replacingOccurrences(of: " ", with: "%20")
 reachability = Reachability()
 
 if reachability!.isReachable
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 do {
 
 
 let videoData = try Data(contentsOf: videoUrl)
 let body = NSMutableData()
 let fname = "test.mp4"
 let mimetype = "video/mp4"
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(videoName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(videoData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 request.httpBody = body as Data
 _ = URLSession.shared
 } catch let error {
 print(error)
 
 }
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 }
 
 }
 task.resume()
 
 }
 else
 {
 // print("Internet is NOT Available")
 Constant.shared.hideIndicator()
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.kMessageNoInternetConnection)
 }
 }
 
 func uploadImagewithDoc(parameters:Dictionary<String, Any>,urlStr : String ,imageName : String , image : UIImage? ,videoName : String, videoURL : URL? , number:String,docImageName:String,docimage : UIImage?,docFileName:String,docFile : URL?)
 {
 
 let urlStr = urlStr.replacingOccurrences(of: " ", with: "%20")
 reachability = Reachability()
 
 if reachability!.isReachable
 {
 if let actualImage = image
 {
 if let videoUrl = videoURL
 {
 if let docImage1 = docimage
 {
 
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 let image_data = UIImageJPEGRepresentation(actualImage, 0.0) //UIImagePNGRepresentation(profileImage.image!)
 
 let docImageDate = UIImageJPEGRepresentation(docImage1, 0.0)
 if(docImageDate == nil)
 {
 return
 }
 if(image_data == nil)
 {
 return
 }
 let body = NSMutableData()
 let fname = "test.jpg"
 let mimetype = "image/jpeg"
 
 do{
 
 let videoData = try Data(contentsOf: videoUrl)
 let vfname = "test.mp4"
 let vmimetype = "video/mp4"
 
 
 for (key, value) in parameters
 {
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(imageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(image_data!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(docImageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(docImageDate!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(videoName)\"; filename=\"\(vfname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(vmimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(videoData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 request.httpBody = body as Data
 _ = URLSession.shared
 } catch let error {
 print(error)
 
 }
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 else if let docFileUrl = docFile
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 let image_data = UIImageJPEGRepresentation(actualImage, 0.0) //UIImagePNGRepresentation(profileImage.image!)
 
 if(image_data == nil)
 {
 return
 }
 let body = NSMutableData()
 let fname = "test.jpg"
 let mimetype = "image/jpeg"
 
 do{
 
 let videoData = try Data(contentsOf: videoUrl)
 let vfname = "test.mp4"
 let vmimetype = "video/mp4"
 
 
 let docData = try Data(contentsOf: docFileUrl)
 let dfname = "test.pdf"
 let dmimetype = "document/pdf"
 
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(imageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(image_data!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(docFileName)\"; filename=\"\(dfname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(dmimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(docData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(videoName)\"; filename=\"\(vfname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(vmimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(videoData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 request.httpBody = body as Data
 _ = URLSession.shared
 } catch let error {
 print(error)
 
 }
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 
 }
 else
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 let image_data = UIImageJPEGRepresentation(actualImage, 0.0) //UIImagePNGRepresentation(profileImage.image!)
 
 if(image_data == nil)
 {
 return
 }
 let body = NSMutableData()
 let fname = "test.jpg"
 let mimetype = "image/jpeg"
 
 do{
 
 let videoData = try Data(contentsOf: videoUrl)
 let vfname = "test.mp4"
 let vmimetype = "video/mp4"
 
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(imageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(image_data!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(videoName)\"; filename=\"\(vfname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(vmimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(videoData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 request.httpBody = body as Data
 _ = URLSession.shared
 } catch let error {
 print(error)
 
 }
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 
 }
 else
 {
 if let docImage1 = docimage
 {
 
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 let image_data = UIImageJPEGRepresentation(actualImage, 0.0) //UIImagePNGRepresentation(profileImage.image!)
 let docImageDate = UIImageJPEGRepresentation(docImage1, 0.0)
 if(docImageDate == nil)
 {
 return
 }
 if(image_data == nil)
 {
 return
 }
 let body = NSMutableData()
 let fname = "test.jpg"
 let mimetype = "image/jpeg"
 
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(imageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(image_data!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(docImageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(docImageDate!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 request.httpBody = body as Data
 _ = URLSession.shared
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 else if let docFileUrl = docFile
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 let image_data = UIImageJPEGRepresentation(actualImage, 0.0) //UIImagePNGRepresentation(profileImage.image!)
 
 
 if(image_data == nil)
 {
 return
 }
 let body = NSMutableData()
 let fname = "test.jpg"
 let mimetype = "image/jpeg"
 
 do{
 let docData = try Data(contentsOf: docFileUrl)
 let dfname = "test.pdf"
 let dmimetype = "document/pdf"
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(imageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(image_data!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(docFileName)\"; filename=\"\(dfname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(dmimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(docData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 request.httpBody = body as Data
 _ = URLSession.shared
 } catch let error {
 print(error)
 
 }
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 else
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 let image_data = UIImageJPEGRepresentation(actualImage, 0.0) //UIImagePNGRepresentation(profileImage.image!)
 
 
 if(image_data == nil)
 {
 return
 }
 let body = NSMutableData()
 let fname = "test.jpg"
 let mimetype = "image/jpeg"
 
 
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(imageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(image_data!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 request.httpBody = body as Data
 _ = URLSession.shared
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 
 }
 }
 }
 else if let videoUrl = videoURL
 {
 if let docImage1 = docimage
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 
 let image_data = UIImageJPEGRepresentation(docImage1, 0.0)
 if(image_data == nil)
 {
 return
 }
 
 let dname = "test.jpg"
 let dmimetype = "image/jpeg"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 do {
 
 
 let videoData = try Data(contentsOf: videoUrl)
 let body = NSMutableData()
 let fname = "test.mp4"
 let mimetype = "video/mp4"
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(videoName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(videoData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(docImageName)\"; filename=\"\(dname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(dmimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(image_data!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 request.httpBody = body as Data
 _ = URLSession.shared
 } catch let error {
 print(error)
 
 }
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 else if let docFileUrl = docFile
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 do {
 
 let docData = try Data(contentsOf: docFileUrl)
 let dfname = "test.pdf"
 let dmimetype = "document/pdf"
 
 let videoData = try Data(contentsOf: videoUrl)
 let body = NSMutableData()
 let fname = "test.mp4"
 let mimetype = "video/mp4"
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(videoName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(videoData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(docFileName)\"; filename=\"\(dfname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(dmimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(docData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 request.httpBody = body as Data
 _ = URLSession.shared
 } catch let error {
 print(error)
 
 }
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 else
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 do {
 
 
 let videoData = try Data(contentsOf: videoUrl)
 let body = NSMutableData()
 let fname = "test.mp4"
 let mimetype = "video/mp4"
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(videoName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(videoData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 request.httpBody = body as Data
 _ = URLSession.shared
 } catch let error {
 print(error)
 
 }
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 }
 else
 {
 
 if let docImage1 = docimage
 {
 
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 
 let docImageDate = UIImageJPEGRepresentation(docImage1, 0.0)
 if(docImageDate == nil)
 {
 return
 }
 
 let body = NSMutableData()
 let fname = "test.jpg"
 let mimetype = "image/jpeg"
 
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(docImageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(docImageDate!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 request.httpBody = body as Data
 _ = URLSession.shared
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 else if let docFileUrl = docFile
 {
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 
 
 
 
 let body = NSMutableData()
 
 
 do{
 let docData = try Data(contentsOf: docFileUrl)
 let dfname = "test.pdf"
 let dmimetype = "document/pdf"
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 
 
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(docFileName)\"; filename=\"\(dfname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(dmimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(docData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 
 request.httpBody = body as Data
 _ = URLSession.shared
 } catch let error {
 print(error)
 
 }
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 else
 {
 
 
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 let body = NSMutableData()
 
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 request.httpBody = body as Data
 _ = URLSession.shared
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 }
 }
 }
 else
 {
 // print("Internet is NOT Available")
 Constant.shared.hideIndicator()
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.kMessageNoInternetConnection)
 }
 }
 
 
 func uploadImageswith(parameters:Dictionary<String, String>,urlStr : String ,imageDictionary:Dictionary<String,UIImage?>,videoDictionary:Dictionary<String,URL?>,documentDictionary:Dictionary<String,URL?>,number:String)
 {
 
 let urlStr = urlStr.replacingOccurrences(of: " ", with: "%20")
 reachability = Reachability()
 
 if reachability!.isReachable
 {
 
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 let body = NSMutableData()
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 for (key, value) in imageDictionary
 {
 if key != ""
 {
 if value != nil
 {
 let image_data = UIImageJPEGRepresentation(value!, 0.0)
 if image_data != nil
 {
 let fname = "test.jpg"
 let mimetype = "image/jpeg"
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(key)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(image_data!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 }
 }
 }
 }
 for (key, value) in videoDictionary
 {
 if key != ""
 {
 if value != nil
 {
 do{
 let videoData = try Data(contentsOf: value!)
 let fname = "test.mp4"
 let mimetype = "video/mp4"
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(key)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(videoData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 }catch let error
 {
 print(error)
 }
 }
 }
 }
 for (key, value) in documentDictionary
 {
 if key != ""
 {
 if value != nil
 {
 do{
 let docData = try Data(contentsOf: value!)
 let dfname = "test.pdf"
 let dmimetype = "document/pdf"
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(key)\"; filename=\"\(dfname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(dmimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(docData)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 
 }catch let error
 {
 print(error)
 }
 }
 }
 }
 
 request.httpBody = body as Data
 _ = URLSession.shared
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 
 
 }
 }
 
 func uploadImageswith(parameters:Dictionary<String, String>,urlStr : String ,imageDictionary:Dictionary<String,UIImage?>,number:String)
 {
 
 let urlStr = urlStr.replacingOccurrences(of: " ", with: "%20")
 reachability = Reachability()
 
 if reachability!.isReachable
 {
 
 let url = URL(string: urlStr)
 
 let request = NSMutableURLRequest(url: url!)
 request.httpMethod = "POST"
 
 let boundary = generateBoundaryString()
 
 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 
 let body = NSMutableData()
 for (key, value) in parameters
 {
 
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 
 }
 for (key, value) in imageDictionary
 {
 if key != ""
 {
 if value != nil
 {
 let image_data = UIImageJPEGRepresentation(value!, 0.0)
 if image_data != nil
 {
 let fname = "test.jpg"
 let mimetype = "image/jpeg"
 body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Disposition:form-data; name=\"\(key)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 body.append(image_data!)
 body.append("\r\n".data(using: String.Encoding.utf8)!)
 body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 }
 }
 }
 }
 
 
 
 
 
 request.httpBody = body as Data
 _ = URLSession.shared
 
 let task = URLSession.shared.dataTask(with: request as URLRequest)
 {            (
 data, response, error) in
 
 guard let _:Data = data, let _:URLResponse = response  , error == nil else
 {
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 
 return
 }
 //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 do
 {
 //create json object from data
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 else
 if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 {
 self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 }
 
 
 }
 catch let error
 {
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 print(error.localizedDescription)
 let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 print(dataString as Any)
 }
 
 }
 task.resume()
 
 
 
 //            if let actualImage = image
 //            {
 //
 //                if let videoUrl = videoURL
 //                {
 //
 //                    let url = URL(string: urlStr)
 //
 //                    let request = NSMutableURLRequest(url: url!)
 //                    request.httpMethod = "POST"
 //
 //                    let boundary = generateBoundaryString()
 //
 //                    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 //
 //                    let image_data = UIImageJPEGRepresentation(actualImage, 0.0) //UIImagePNGRepresentation(profileImage.image!)
 //
 //                    if(image_data == nil)
 //                    {
 //                        return
 //                    }
 //                    let body = NSMutableData()
 //                    let fname = "test.jpg"
 //                    let mimetype = "image/jpeg"
 //
 //                    do{
 //
 //                        let videoData = try Data(contentsOf: videoUrl)
 //                        let vfname = "test.mp4"
 //                        let vmimetype = "video/mp4"
 //
 //
 //                        for (key, value) in parameters
 //                        {
 //
 //                            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //                            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 //                            body.append("\r\n".data(using: String.Encoding.utf8)!)
 //
 //                        }
 //                        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //                        body.append("Content-Disposition:form-data; name=\"\(imageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 //                        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 //                        body.append(image_data!)
 //                        body.append("\r\n".data(using: String.Encoding.utf8)!)
 //                        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 //
 //
 //                        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //                        body.append("Content-Disposition:form-data; name=\"\(videoName)\"; filename=\"\(vfname)\"\r\n".data(using: String.Encoding.utf8)!)
 //                        body.append("Content-Type: \(vmimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 //                        body.append(videoData)
 //                        body.append("\r\n".data(using: String.Encoding.utf8)!)
 //                        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 //
 //                        request.httpBody = body as Data
 //                        _ = URLSession.shared
 //                    } catch let error {
 //                        print(error)
 //
 //                    }
 //
 //                    let task = URLSession.shared.dataTask(with: request as URLRequest)
 //                    {            (
 //                        data, response, error) in
 //
 //                        guard let _:Data = data, let _:URLResponse = response  , error == nil else
 //                        {
 //
 //                            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                            self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 //                            print(dataString as Any)
 //
 //                            return
 //                        }
 //                        //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                        do
 //                        {
 //                            //create json object from data
 //                            if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 //                            {
 //                                self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 //                            }
 //                            else
 //                                if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 //                                {
 //                                    self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 //                            }
 //
 //
 //                        }
 //                        catch let error
 //                        {
 //                            Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 //                            print(error.localizedDescription)
 //                            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                            self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 //                            print(dataString as Any)
 //                        }
 //
 //                    }
 //                    task.resume()
 //                }
 //                else
 //                {
 //                    let url = URL(string: urlStr)
 //
 //                    let request = NSMutableURLRequest(url: url!)
 //                    request.httpMethod = "POST"
 //
 //                    let boundary = generateBoundaryString()
 //
 //                    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 //
 //                    let image_data = UIImageJPEGRepresentation(actualImage, 0.0) //UIImagePNGRepresentation(profileImage.image!)
 //
 //                    if(image_data == nil)
 //                    {
 //                        return
 //                    }
 //                    let body = NSMutableData()
 //                    let fname = "test.jpg"
 //                    let mimetype = "image/jpeg"
 //
 //
 //                    for (key, value) in parameters
 //                    {
 //
 //                        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //                        body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 //                        body.append("\r\n".data(using: String.Encoding.utf8)!)
 //
 //                    }
 //                    body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //                    body.append("Content-Disposition:form-data; name=\"\(imageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 //                    body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 //                    body.append(image_data!)
 //                    body.append("\r\n".data(using: String.Encoding.utf8)!)
 //                    body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 //                    request.httpBody = body as Data
 //                    _ = URLSession.shared
 //
 //                    let task = URLSession.shared.dataTask(with: request as URLRequest)
 //                    {            (
 //                        data, response, error) in
 //
 //                        guard let _:Data = data, let _:URLResponse = response  , error == nil else
 //                        {
 //                            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                            self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 //                            print(dataString as Any)
 //
 //                            return
 //                        }
 //                        //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                        do
 //                        {
 //                            //create json object from data
 //                            if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 //                            {
 //                                self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 //                            }
 //                            else
 //                                if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 //                                {
 //                                    self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 //                            }
 //
 //
 //                        }
 //                        catch let error
 //                        {
 //                            Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 //                            print(error.localizedDescription)
 //                            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                            self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 //                            print(dataString as Any)
 //                        }
 //
 //                    }
 //                    task.resume()
 //                }
 //            }
 //            else if let videoUrl = videoURL
 //            {
 //                let url = URL(string: urlStr)
 //
 //                let request = NSMutableURLRequest(url: url!)
 //                request.httpMethod = "POST"
 //
 //                let boundary = generateBoundaryString()
 //
 //                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 //
 //                do {
 //
 //
 //                    let videoData = try Data(contentsOf: videoUrl)
 //                    let body = NSMutableData()
 //                    let fname = "test.mp4"
 //                    let mimetype = "video/mp4"
 //
 //                    for (key, value) in parameters
 //                    {
 //
 //                        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //                        body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 //                        body.append("\r\n".data(using: String.Encoding.utf8)!)
 //
 //                    }
 //                    body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //                    body.append("Content-Disposition:form-data; name=\"\(videoName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 //                    body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 //                    body.append(videoData)
 //                    body.append("\r\n".data(using: String.Encoding.utf8)!)
 //                    body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 //                    request.httpBody = body as Data
 //                    _ = URLSession.shared
 //                } catch let error {
 //                    print(error)
 //
 //                }
 //                let task = URLSession.shared.dataTask(with: request as URLRequest)
 //                {            (
 //                    data, response, error) in
 //
 //                    guard let _:Data = data, let _:URLResponse = response  , error == nil else
 //                    {
 //
 //                        let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                        self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 //                        print(dataString as Any)
 //                        return
 //                    }
 //                    //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                    do
 //                    {
 //                        //create json object from data
 //                        if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 //                        {
 //                            self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 //                        }
 //                        else
 //                            if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 //                            {
 //                                self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 //                        }
 //
 //
 //                    }
 //                    catch let error
 //                    {
 //                        Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 //                        print(error.localizedDescription)
 //                        let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                        self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 //                        print(dataString as Any)
 //                    }
 //
 //                }
 //                task.resume()
 //            }
 //            else
 //            {
 //                let url = URL(string: urlStr)
 //
 //                let request = NSMutableURLRequest(url: url!)
 //                request.httpMethod = "POST"
 //
 //                let boundary = generateBoundaryString()
 //
 //                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 //                let body = NSMutableData()
 //
 //                for (key, value) in parameters
 //                {
 //
 //                    body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //                    body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 //                    body.append("\r\n".data(using: String.Encoding.utf8)!)
 //
 //                }
 //                request.httpBody = body as Data
 //                _ = URLSession.shared
 //
 //                let task = URLSession.shared.dataTask(with: request as URLRequest)
 //                {            (
 //                    data, response, error) in
 //
 //                    guard let _:Data = data, let _:URLResponse = response  , error == nil else
 //                    {
 //
 //                        let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                        self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 //                        print(dataString as Any)
 //
 //                        return
 //                    }
 //                    //let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                    do
 //                    {
 //                        //create json object from data
 //                        if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
 //                        {
 //                            self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 //                        }
 //                        else
 //                            if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Array<Any> //as? [String: Any]
 //                            {
 //                                self.delegate.APIResponseArrived(json as AnyObject, error: "1", number: number)
 //                        }
 //
 //
 //                    }
 //                    catch let error
 //                    {
 //                        Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.somthingWrongMsg)
 //                        print(error.localizedDescription)
 //                        let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //                        self.delegate.APIResponseArrived([] as AnyObject, error: "0", number: number)
 //                        print(dataString as Any)
 //                    }
 //
 //                }
 //                task.resume()
 //            }
 }
 else
 {
 // print("Internet is NOT Available")
 Constant.shared.hideIndicator()
 Constant.shared.showAlert(projectTitle: Constant.AppMessage.ProjectTitle, message: Constant.AppMessage.kMessageNoInternetConnection)
 }
 }
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 func generateBoundaryString() -> String
 {
 return "Boundary-\(UUID().uuidString)"
 }
 
 
 
 
 }
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ////////////////////
 //@IBAction func uploadImage(_ sender: Any)
 //{
 //    print("Up")
 //    //UploadRequest()
 //    let temp = WebHandler()
 //    temp.delegate=self
 //    let data = ["user_id" : "22"]
 //    // "http://74.208.12.101/snsapi/save_image.php"
 //
 //    temp.UploadRequest(parameters: data, urlStr: "http://74.208.12.101/snsapi/save_image.php", imageName: "photo_pics", actualImage: image.image!)
 //
 //
 //}
 //func imageUploadResponse(_ Response:AnyObject, error : String)
 //{
 //    print(Response)
 //}
 //@IBAction func getServiceCallBtnClicked(_ sender: Any)
 //{
 //    //Show Indicator
 //    myActivityIndicator.startAnimating()
 //    //MARK: - Get Request
 //    let temp = WebHandler()
 //    temp.delegate=self
 //
 //    let name = "pqr" as NSString
 //    let pass = "pass123" as NSString
 //
 //    let url = WebHandler.mainUrl + "user-login?user_name=\(name)&user_password=\(pass)" as NSString
 //
 //    print(url)
 //    temp.doRequestGet(urlStr:url)
 //
 //}
 //
 //@IBAction func postServiceCallBtnClicked(_ sender: Any)
 //{
 //    //Show Indicato
 //    myActivityIndicator.startAnimating()
 //    //MARK: - Get Request
 //    let temp = WebHandler()
 //    temp.delegate=self
 //
 //    let name = "pqr" as String
 //    let pass = "pass123" as String
 //
 //    let url = WebHandler.mainUrl+"user-login" as NSString
 //
 //    print(url)
 //
 //    let parameter = ["user_name":name , "user_password":pass]
 //    temp.doRequestPost(parameters: parameter as AnyObject, urlStr: url)
 //
 //
 //}
 ////MARK:- Get Request Service Resopnse
 //func APIResponseArrived(_ Response:AnyObject, error : String)
 //{
 //    if error != "0"
 //    {
 //        if Response is Dictionary<String, AnyObject>
 //        {
 //            print(Response)
 //            let Message = Response["Message"] as! NSString
 //
 //            if "success" == Response["Status"] as! String
 //            {
 //                print(Response)
 //                //Hide Indicator
 //                myActivityIndicator.isHidden = true
 //                myActivityIndicator.stopAnimating()
 //                myActivityIndicator.isHidden = true
 //                WebHandler.showAlertWithTilte(title: WebHandler.projectTitle , message: Message)
 //            }
 //            else
 //            {
 //                //Hide Indicator
 //                myActivityIndicator.isHidden = true
 //                myActivityIndicator.stopAnimating()
 //                WebHandler.showAlertWithTilte(title: WebHandler.projectTitle , message: Message)
 //            }
 //        }
 //    }
 //    else
 //    {
 //        //Hide Indicator
 //        myActivityIndicator.isHidden = true
 //        myActivityIndicator.stopAnimating()
 //        WebHandler.showAlertWithTilte(title: WebHandler.projectTitle , message: WebHandler.somthingWrongMsg as NSString)
 //    }
 //}
 
 //
 //func UploadRequest(parameters:Dictionary<String, String>,urlStr : String ,imageName : String , actualImage : UIImage)
 //{
 //    let url = URL(string: urlStr)
 //
 //    let request = NSMutableURLRequest(url: url!)
 //    request.httpMethod = "POST"
 //
 //    let boundary = generateBoundaryString()
 //
 //    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
 //
 //
 //
 //    let image_data = UIImageJPEGRepresentation(actualImage, 0.0) //UIImagePNGRepresentation(profileImage.image!)
 //
 //
 //
 //    if(image_data == nil)
 //    {
 //        return
 //    }
 //
 //
 //    let body = NSMutableData()
 //
 //    let fname = "test.jpg"
 //    let mimetype = "image/jpeg"
 //
 //
 //    for (key, value) in parameters
 //    {
 //
 //        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //        body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
 //        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //
 //    }
 //
 //    body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //    body.append("Content-Disposition:form-data; name=\"test\"\r\n\r\n".data(using: String.Encoding.utf8)!)
 //    body.append("hi\r\n".data(using: String.Encoding.utf8)!)
 //
 //    body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
 //    body.append("Content-Disposition:form-data; name=\"\(imageName)\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
 //    body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
 //    body.append(image_data!)
 //    body.append("\r\n".data(using: String.Encoding.utf8)!)
 //
 //    body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
 //    //        print("Body:-", body)
 //    request.httpBody = body as Data
 //    _ = URLSession.shared
 //
 //    let task = URLSession.shared.dataTask(with: request as URLRequest)
 //    {            (
 //        data, response, error) in
 //
 //        guard let _:Data = data, let _:URLResponse = response  , error == nil else
 //        {
 //            // print("error")
 //            self.delegate.imageUploadResponse!(error! as AnyObject, error: "0")
 //            return
 //        }
 //
 //        let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
 //        self.delegate.imageUploadResponse!(dataString!, error: "1")
 //        //print(dataString ?? "nothing")
 //    }
 //    task.resume()
 //}
 //func generateBoundaryString() -> String
 //{
 //    return "Boundary-\(UUID().uuidString)"
 //}
 

 
 */
