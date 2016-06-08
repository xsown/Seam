//    NSManagedObject+CKRecord.swift
//
//    The MIT License (MIT)
//
//    Copyright (c) 2015 Nofel Mahmood ( https://twitter.com/NofelMahmood )
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.


import Foundation
import CoreData
import CloudKit

extension NSManagedObject {
    private func setAttributesValues(ofCKRecord ckRecord:CKRecord, withValuesOfAttributeWithKeys keys: [String]?) {
        var attributes: [String] = [String]()
        if keys != nil {
            attributes = keys!
        } else {
            attributes = Array(self.entity.attributesByNameByRemovingBackingStoreAttributes().keys)
        }
        let valuesDictionary = self.dictionaryWithValuesForKeys(attributes)
        for (key,_) in valuesDictionary {
            let attributeDescription = self.entity.attributesByName[key]
            if attributeDescription != nil && self.valueForKey(attributeDescription!.name) != nil {
                switch(attributeDescription!.attributeType) {
                case .StringAttributeType:
                    ckRecord.setObject(self.valueForKey(attributeDescription!.name) as! String, forKey: attributeDescription!.name)
                case .DateAttributeType:
                    ckRecord.setObject(self.valueForKey(attributeDescription!.name) as! NSDate, forKey: attributeDescription!.name)
                case .TransformableAttributeType:
                    fallthrough
                case .BinaryDataAttributeType:
                    ckRecord.setObject(self.valueForKey(attributeDescription!.name) as! NSData, forKey: attributeDescription!.name)
                case .BooleanAttributeType:
                    ckRecord.setObject(self.valueForKey(attributeDescription!.name) as! NSNumber, forKey: attributeDescription!.name)
                case .DecimalAttributeType:
                    ckRecord.setObject(self.valueForKey(attributeDescription!.name) as! NSNumber, forKey: attributeDescription!.name)
                case .DoubleAttributeType:
                    ckRecord.setObject(self.valueForKey(attributeDescription!.name) as! NSNumber, forKey: attributeDescription!.name)
                case .FloatAttributeType:
                    ckRecord.setObject(self.valueForKey(attributeDescription!.name) as! NSNumber, forKey: attributeDescription!.name)
                case .Integer16AttributeType:
                    ckRecord.setObject(self.valueForKey(attributeDescription!.name) as! NSNumber, forKey: attributeDescription!.name)
                case .Integer32AttributeType:
                    ckRecord.setObject(self.valueForKey(attributeDescription!.name) as! NSNumber, forKey: attributeDescription!.name)
                case .Integer64AttributeType:
                    ckRecord.setObject(self.valueForKey(attributeDescription!.name) as! NSNumber, forKey: attributeDescription!.name)
                default:
                    break
                }
            } else if attributeDescription != nil && self.valueForKey(attributeDescription!.name) == nil {
                ckRecord.setObject(nil, forKey: attributeDescription!.name)
            }
        }
    }
    
    private func setRelationshipValues(ofCKRecord ckRecord:CKRecord, withValuesOfRelationshipWithKeys keys: [String]?) {
        var relationships: [String] = [String]()
        if keys != nil {
            relationships = keys!
        } else {
            relationships = Array(self.entity.toOneRelationshipsByName().keys)
        }
        for relationship in relationships {
            let relationshipManagedObject = self.valueForKey(relationship)
            if relationshipManagedObject != nil {
                let recordIDString: String = self.valueForKey(SMLocalStoreRecordIDAttributeName) as! String
                let ckRecordZoneID: CKRecordZoneID = CKRecordZoneID(zoneName: SMStoreCloudStoreCustomZoneName, ownerName: CKOwnerDefaultName)
                let ckRecordID: CKRecordID = CKRecordID(recordName: recordIDString, zoneID: ckRecordZoneID)
                let ckReference: CKReference = CKReference(recordID: ckRecordID, action: CKReferenceAction.DeleteSelf)
                ckRecord.setObject(ckReference, forKey: relationship)
            }
        }
    }
    
    public func createOrUpdateCKRecord(usingValuesOfChangedKeys keys: [String]?) -> CKRecord? {
        let encodedFields: NSData? = self.valueForKey(SMLocalStoreRecordEncodedValuesAttributeName) as? NSData
        var ckRecord: CKRecord?
        if encodedFields != nil {
            ckRecord = CKRecord.recordWithEncodedFields(encodedFields!)
        } else {
            let recordIDString = self.valueForKey(SMLocalStoreRecordIDAttributeName) as! String
            let ckRecordZoneID: CKRecordZoneID = CKRecordZoneID(zoneName: SMStoreCloudStoreCustomZoneName, ownerName: CKOwnerDefaultName)
            let ckRecordID: CKRecordID = CKRecordID(recordName: recordIDString, zoneID: ckRecordZoneID)
            ckRecord = CKRecord(recordType: self.entity.name!, recordID: ckRecordID)
        }
        if keys != nil {
            let attributeKeys = self.entity.attributesByName.filter { (object) -> Bool in
                return keys!.contains(object.0)
                }.map { (object) -> String in
                    return object.0
            }
            let relationshipKeys = self.entity.relationshipsByName.filter { (object) -> Bool in
                return keys!.contains(object.0)
                }.map { (object) -> String in
                    return object.0
            }
            self.setAttributesValues(ofCKRecord: ckRecord!, withValuesOfAttributeWithKeys: attributeKeys)
            self.setRelationshipValues(ofCKRecord: ckRecord!, withValuesOfRelationshipWithKeys: relationshipKeys)
            return ckRecord
        }
        self.setAttributesValues(ofCKRecord: ckRecord!, withValuesOfAttributeWithKeys: nil)
        self.setRelationshipValues(ofCKRecord: ckRecord!, withValuesOfRelationshipWithKeys: nil)
        return ckRecord
    }
}
