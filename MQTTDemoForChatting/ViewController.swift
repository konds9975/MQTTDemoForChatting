//
//  ViewController.swift
//  MQTTDemoForChatting
//
//  Created by Inkswipe on 6/7/18.
//  Copyright © 2018 Fortune4 Technologies. All rights reserved.
//

import UIKit
import Moscapsule
class ViewController: UIViewController {


    var mqttClient : MQTTClient!
    override func viewDidLoad() {
        super.viewDidLoad()
     
        // set MQTT Client Configuration
        let mqttConfig = MQTTConfig(clientId: "ios", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        //mqttConfig.mqttAuthOpts = MQTTAuthOpts(username: "username", password: "password")
        mqttConfig.onPublishCallback = { messageId in
            NSLog("published (mid=\(messageId))")
        }
        mqttConfig.onMessageCallback = { meaage in
            
            if meaage.topic == "fabit/user/1" {
                print("MQTT Message received: payload=\(String(describing: meaage.payloadString))")
                DispatchQueue.main.sync {
               
                self.logTextView.text = meaage.payloadString
                    
                }
            }
            else
            {
                print("MQTT Message received: payload=\(String(describing: meaage.payloadString))")
            }
            
        }
        
//        mqttConfig.onConnectCallback = { returnCode in
//            if returnCode == ReturnCode.success {
//                print("Sucesss Connect")
//
//            }
//            else {
//                print("fail to Connect")
//            }
//        }
//
//        mqttConfig.onDisconnectCallback = { reasonCode in
//            if reasonCode == ReasonCode.disconnect_requested {
//                print("Sucesss disConnect")
//            } else  {
//                print("fail to disConnect")
//
//            }
//        }
//        mqttConfig.onPublishCallback = { messageId in
//            // successful publish
//            print("successful publish message")
//        }
//        mqttConfig.onMessageCallback = { mqttMessage in
//
//
//            if mqttMessage.topic == "fabit/user/1" {
//                print("MQTT Message received: payload=\(String(describing: mqttMessage.messageId))")
//            }
//            else
//            {
//                print("MQTT Message received: payload=\(String(describing: mqttMessage.messageId))")
//            }
//        }
//        mqttConfig.onSubscribeCallback = { (messageId, grantedQos) in
//            print("subscribed (mid=\(messageId),grantedQos=\(grantedQos))")
//        }

        
        // create new MQTT Connection
        mqttClient = MQTT.newConnection(mqttConfig)
        mqttClient.publish(string:"Hello CloudAMQP MQTT" , topic: "fabit/coach/1", qos:0, retain: false)
        // publish and subscribe
        mqttClient.subscribe("fabit/user/1", qos: 0)
        
        //mqttClient.reconnect()
        
        //mqttClient.disconnect()
        
    }

    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var messageText: UITextField!
    @IBAction func sendBtnAction(_ sender: Any) {
        if messageText.text != ""
        {
            mqttClient.publish(string:messageText.text! , topic: "fabit/coach/1", qos:0, retain: false)
        }
        
    }
    
  


}

