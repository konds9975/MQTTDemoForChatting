//
//  DBManager.swift
//  MQTTDemoForChatting
//
//  Created by Hitendra Bhoir on 20/06/18.
//  Copyright © 2018 Fortune4 Technologies. All rights reserved.
//


import Foundation
import UIKit
import RealmSwift

class MessageInfo: Object
{
    @objc dynamic var date : Date!
    @objc dynamic var type : String!
    @objc dynamic var value : String!
    @objc dynamic var user_id: String!
    @objc dynamic var coach_id : String!
    @objc dynamic var sent_by: String!
    @objc dynamic var message_id: String!
    @objc dynamic var is_delivered : String!
    @objc dynamic var delivered_on: String!
    @objc dynamic var is_read : String!
    @objc dynamic var read_on: String!
    
    
    func initData(type : String?,value : String?,user_id: String?,coach_id : String?, sent_by: String?,message_id: String?,is_delivered : String?,delivered_on: String?,is_read : String?,read_on: String?,date:Date?)
    {
        self.type = type ?? ""
        self.value = value ?? ""
        self.user_id = user_id ?? ""
        self.coach_id = coach_id ?? ""
        self.sent_by = sent_by ?? ""
        self.message_id = message_id ?? ""
        self.is_delivered = is_delivered ?? ""
        self.delivered_on = delivered_on ?? ""
        self.is_read = is_read ?? ""
        self.read_on = read_on ?? ""
        self.date = date ?? Date()
        
    }
    
    
}
class DBManager: NSObject
{
    var realm : Realm!
    static let shared: DBManager = {
        let instance = DBManager()
        // setup code
        return instance
    }()
    // MARK: - Initialization Method
    override init() {
        super.init()
        realm = try! Realm()
    }
    func realmDataBaseSetup()
    {
        
        let realm = try! Realm()
        let folderPath = realm.configuration.fileURL!.deletingLastPathComponent().path
        print("Database Path\(folderPath)")
    }
    func insertModelInDataBase(messageInfo:[MessageInfo])
    {
        
            try! self.realm.write
            {
                self.realm.add(messageInfo)
                
            }
        
    }
    func getAllMessages() -> [MessageInfo] {
        
        let messageListArray = realm.objects(MessageInfo.self)
        var dataSource = [MessageInfo]()
        dataSource.append(contentsOf: messageListArray)
        return dataSource
    }
    
    func updateIsDelivery(messageId:String!,isDelivery:String!,isRead : String!)
    {
        
        let messageInfo = realm.objects(MessageInfo.self).filter() { $0.message_id == messageId }
        var dataSource = [MessageInfo]()
        dataSource.append(contentsOf: messageInfo)
        if dataSource.count != 0
        {
            let temp = dataSource[0]
            try! realm.write
            {
                temp.is_delivered = isDelivery
                temp.is_read = isRead
            }
        }
    }

    
    
//    func getDataIntModelByDateSymptomDataMoelWithDate(dateString:String!) -> [SymptomDataMoelWithDate] {
//
//        let personListArray = realm.objects(SymptomDataMoelWithDate.self).filter() { $0.dateString == dateString }
//        var dataSource = [SymptomDataMoelWithDate]()
//        dataSource.append(contentsOf: personListArray)
//        return dataSource.reversed()
//    }
//    func deleteModelInDataBaseSymptomDataMoelWithDate(symptomDataModel:[SymptomDataMoelWithDate])
//    {
//        try! realm.write
//        {
//            self.realm.delete(symptomDataModel)
//
//        }
//
//    }
    
//    func updateData(isWheezing:String!,isCough:String!,isChestTightness:String!,isDifficultyBreathing:String!,optionsString:String!,symptomDateandTime:Date!,dateString:String!,symptomDataMoelWithDate:SymptomDataMoelWithDate!)
//    {
//        try! realm.write
//        {
//            symptomDataMoelWithDate.isWheezing = isWheezing
//            symptomDataMoelWithDate.isCough = isCough
//            symptomDataMoelWithDate.isChestTightness = isChestTightness
//            symptomDataMoelWithDate.isDifficultyBreathing = isDifficultyBreathing
//            symptomDataMoelWithDate.optionsString = optionsString
//            symptomDataMoelWithDate.symptomDateandTime = symptomDateandTime
//            symptomDataMoelWithDate.dateString = dateString
//        }
//    }
//    func updateData(isResueInhalerUsed:String!,numberOfpuffs:String!,timeString:String!,location:String!,possibleTrigger:String!,isLogASAttack:String!,symptomDataMoelWithDate:SymptomDataMoelWithDate!)
//    {
//        try! realm.write
//        {
//            symptomDataMoelWithDate.isResueInhalerUsed = isResueInhalerUsed
//            symptomDataMoelWithDate.numberOfpuffs = numberOfpuffs
//            symptomDataMoelWithDate.timeString = timeString
//            symptomDataMoelWithDate.location = location
//            symptomDataMoelWithDate.possibleTrigger = possibleTrigger
//            symptomDataMoelWithDate.isLogASAttack = isLogASAttack
//
//        }
//    }
//
//
//
//
//    func insertModelInDataBase(symptomDataModel:[SymptomDataModel])
//    {
//        try! realm.write
//        {
//            realm.add(symptomDataModel)
//
//        }
//    }
//    func deleteModelInDataBase(symptomDataModel:[SymptomDataModel])
//    {
//        try! realm.write
//        {
//            self.realm.delete(symptomDataModel)
//
//        }
//
//    }
//
//    func getAllDataIntModel() -> [SymptomDataModel] {
//
//        let personListArray = realm.objects(SymptomDataModel.self)
//        var dataSource = [SymptomDataModel]()
//        dataSource.append(contentsOf: personListArray)
//        return dataSource.reversed()
//    }
//    func getAllDateDataIntModel() -> [String] {
//
//        let personListArray = realm.objects(SymptomDataModel.self)
//        var dataSource = [SymptomDataModel]()
//        dataSource.append(contentsOf: personListArray)
//
//        var dateArray = [String]()
//        for date in dataSource
//        {
//            dateArray.append(date.dateString)
//        }
//        return dateArray
//    }
//
//
//
//
//    func getDataIntModelByDate(dateString:String!) -> [SymptomDataModel] {
//
//        let personListArray = realm.objects(SymptomDataModel.self).filter() { $0.dateString == dateString }
//        var dataSource = [SymptomDataModel]()
//        dataSource.append(contentsOf: personListArray)
//        return dataSource.reversed()
//    }
//
//    ////////
//    func insertProductListDataModel(productListDataModel:[ProductListDataModel])
//    {
//        try! realm.write
//        {
//            realm.add(productListDataModel)
//
//        }
//    }
//    func getAllProductListModels() -> [ProductListDataModel] {
//
//        let productListArray = realm.objects(ProductListDataModel.self).filter(){ $0.patient_type == "Asthma" ||  $0.patient_type == "Asthma + COPD" || $0.patient_type == "Asthma + AR" || $0.patient_type == "Asthma + Pead Asthma"}
//        var dataSource = [ProductListDataModel]()
//        dataSource.append(contentsOf: productListArray)
//        return dataSource.reversed()
//    }
    
    
}
