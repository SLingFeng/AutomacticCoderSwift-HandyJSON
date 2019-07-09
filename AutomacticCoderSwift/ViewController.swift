//
//  ViewController.swift
//  AutomacticCoderSwift
//
//  Created by 孙凌锋 on 2017/11/24.
//  Copyright © 2017年 孙凌锋. All rights reserved.
//

import Cocoa

enum JsonValueType : Int {
    case kOther = -1
    case kString = 0
    case kNumber = 1
    case kArray = 2
    case kDictionary = 3
    case kBool = 4
}

class ViewController: NSViewController {

    
//    var _templateSwift = NSMutableString(contentsOfFile: Bundle.main.path(forResource: "json_swift", ofType: "txt")!, encoding: NSUTF8StringEncoding.rawValue)
    var _templateSwift = NSMutableString()
    
    var _path : String?
    
    
    @IBOutlet weak var classNameTF: NSTextField!
    @IBOutlet weak var sBtn: NSButton!
    @IBOutlet var jsonTV: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    @IBAction func sBtnClick(_ sender: Any) {
        _templateSwift = NSMutableString(string: try! String(contentsOfFile: Bundle.main.path(forResource: "json_swift", ofType: "txt") ?? "", encoding: .utf8))
        
        if self.classNameTF.stringValue.count == 0 {
            self.message("没有输入Class名！", "")
            return
        }
        if self.jsonTV.string.count == 0 {
            self.message("Json无数据", "")
            return
        }
        //开始解析json
        var jsonStr = self.jsonTV.string.replacingOccurrences(of: "“", with: "\"")
        jsonStr = jsonStr.replacingOccurrences(of: "”", with: "\"")
        
        let response = jsonStr.data(using: .utf8)
        let dict = (try? JSONSerialization.jsonObject(with: response!, options: .mutableLeaves)) as? [AnyHashable: Any]
        
        if (dict != nil) {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true;
            panel.canChooseFiles = false
            weak var weakSelf: ViewController? = self
            panel.begin(completionHandler: { (_ result) -> Void in
                
//            })
//            panel.beginSheet(NSApplication.shared.keyWindow!, completionHandler: {(_ result) -> Void in
                if result.rawValue == 0 {
                    return
                }
                weakSelf?._path = panel.url?.path
                
                weakSelf?.generateClass((weakSelf?.classNameTF.stringValue)!, dict! as NSDictionary)
                weakSelf?.writeToFile()
            })
            
        }else {
             self.message("JSON格式不正确！", "")
        }
    }
    
    
    func message(_ str : String, _ str2 :String) -> Void {
        
        let alert = NSAlert()
        alert.messageText = str
        alert.runModal()
//        let string = str2.copy()
//        self.jsonTV.string = str;
//        self.jsonTV.textColor = .red
//        self.jsonTV.font = NSFont.systemFont(ofSize: 50)
//        self.sBtn.isEnabled = false
//
//
//        self.perform(#selector(self.normal), with: string, afterDelay: 1)
    }
    
    @objc func normal(_ str : String) -> Void {
        self.jsonTV.string = str;
        self.jsonTV.textColor = .black
        self.jsonTV.font = NSFont.systemFont(ofSize: 12)
        self.sBtn.isEnabled = true
    }
    
    
    func generateClass(_ nameTemp: String, _ json: NSDictionary) -> Void {
        
        let templateModelSwift = NSMutableString(string: try! String(contentsOfFile: Bundle.main.path(forResource: "oneModel_swift", ofType: "txt") ?? "", encoding: .utf8))
        
        //property
        let property = NSMutableString()
        
        let prefix = self.classNameTF.stringValue
        var name = nameTemp as String;
        
        if !name.isEqual(self.classNameTF.stringValue) {
            name = "\(prefix)\(name)Model"
        }else {
            name = "\(name)Model"
        }
        NSLog("name:%@, prefix:%@", name, prefix)
//        for key: NSString in json.keys {
        for i in 0..<json.count {
            let key = json.allKeys[i] as! NSString
            print(key)
            let v = json[key]
//            print(v)
            
            let type = self.type(json[key] as Any) as JsonValueType
            
            switch (type) {
            case .kString:
                property.append("///\(String(describing: v))\n    ")
                property.append("var \(key) : \(typeName(type)) = \"\"\n\n    ")
                break
                
//            case .kBool:
//                property.append("///\(String(describing: v))\n    ")
//                property.append("var \(key) : \(typeName(type)) = false\n\n    ")
//                break
                
            case .kNumber:
                property.append("///\(String(describing: v))\n    ")
                property.append("var \(key) = \(typeName(type))()\n\n    ")
                break
                
            case .kArray:
                if self.isDataArray(json[key] as! [Dictionary<String, Any>]) {
                    let arr = json[key] as! NSArray
                    property.append("var \(key) : [\(prefix)\(uppercaseFirstChar(key))Model] = []\n\n    ")
                    self.generateClass(uppercaseFirstChar(key), arr.object(at: 0) as! NSDictionary)
                }
                
//
//                if arr.count != 0 {
//
//                }
                break
                
            case .kDictionary:
                property.append("var \(key) : \(prefix)\(uppercaseFirstChar(key))Model?\n\n    ")
                if let dic: NSDictionary = json[key] as? NSDictionary {
                    if dic.count != 0 {
                        self.generateClass(uppercaseFirstChar(key), dic)
                    }
                }
                break
                
            default:
                property.append("///\(String(describing: v))\n    ")
                property.append("var \(key) : \(typeName(type)) = \"\"\n\n    ")
                break
            }
        }
        
        templateModelSwift.replaceOccurrences(of: "#name#", with: name, options: .caseInsensitive, range: NSRange(location: 0, length: templateModelSwift.length))
        
        templateModelSwift.replaceOccurrences(of: "#property#", with: property as String, options: .caseInsensitive, range: NSRange(location: 0, length: templateModelSwift.length))
        
        //写文件
        _templateSwift.append(templateModelSwift as String)
    }
    
    func writeToFile() {
        _templateSwift.replaceOccurrences(of: "#name#", with: "\(self.classNameTF.stringValue)Model", options: .caseInsensitive, range: NSRange(location: 0, length: (self.classNameTF.stringValue as NSString).length))

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        _templateSwift.replaceOccurrences(of: "#time#", with: formatter.string(from: Date()), options: .caseInsensitive, range: NSRange(location: 0, length: _templateSwift.length))
        
        do {
            try _templateSwift.write(toFile: "\(_path!)/\(self.classNameTF.stringValue)Model.swift", atomically: false, encoding: String.Encoding.utf8.rawValue)
//            var data = Data()
//            data.append((_templateSwift?.data(using: String.Encoding.utf8.rawValue))!)
//            try data.write(to: URL(fileURLWithPath: "\(_path!)/\(self.classNameTF.stringValue)Model.swift"))
//            _templateSwift?.write(to: URL(fileURLWithPath: "\(_path!)/\(self.classNameTF.stringValue)Model.swift"), atomically: true, encoding: String.Encoding.utf8.rawValue)
        } catch  {
            
        }
//        if !fileManage.fileExistsAtPath(filePath!){
//            let bundlePath = NSBundle.mainBundle().resourcePath
//            let defaultFilePath = bundlePath! + "/\(NoteFile)"
//            do{
//                try fileManage.copyItemAtPath(defaultFilePath, toPath: filePath!)
//            }catch{
//                print("错误写入文件!")
//            }
//        }
//        let fileManage = FileManager()
//        let filePath = _path
//        let uf = fileManage.urls(for: .documentDirectory, in: .userDomainMask)
//        let url = uf[0]
//        createFile(name: "\(_path!)/\(self.classNameTF.stringValue).swift", fileBaseUrl: url)
//        if !fileManage.fileExists(atPath: filePath!) {
//            fileManage.co
//        }
        
    }
    
//    func createFile(name:String, fileBaseUrl:URL){
//        let manager = FileManager.default
//
//        let file = fileBaseUrl.appendingPathComponent(name)
//        print("文件: \(file)")
//        let exist = manager.fileExists(atPath: file.path)
//        if !exist {
//            let data = Data(base64Encoded:"aGVsbG8gd29ybGQ=" ,options:.ignoreUnknownCharacters)
//            let createSuccess = manager.createFile(atPath: file.path,contents:data,attributes:nil)
//            print("文件创建结果: \(createSuccess)")
//        }
//    }
    func isDataArray(_ theArray: [Dictionary<String, Any>]) -> Bool {
        if theArray.count <= 0 {
            return false
        }

        for item: Any in theArray {
            if self.type(item) != JsonValueType.kDictionary {
                return false
            }
        }

        let keys = NSMutableSet()
        let tempDic = theArray[0]
        for key: String in tempDic.keys {
            keys.add(key)
        }

        for item: Dictionary in theArray {
            let newKeys = NSMutableSet()

            for key: String in item.keys {
                newKeys.add(key)
            }

            if keys.isEqual(to: newKeys) == false {
                return false
            }
        }
        return true
    }
    
    func type(_ obj: Any) -> JsonValueType {
        if (obj is NSString) {
            return JsonValueType.kString
        }else if ((obj as AnyObject).className == "__NSCFBoolean") || obj is Bool {
            return JsonValueType.kBool
        }else if obj is [Any] {
            return JsonValueType.kArray
        }else if obj is [AnyHashable: Any] {
            return JsonValueType.kDictionary
//        }else if obj is NSNumber {
//            return JsonValueType.kNumber
        }else {
            return JsonValueType.kString
        }
        
        
//        if (obj as AnyObject).className == "__NSCFString" || (obj as AnyObject).className == "__NSCFConstantString" {
//            return JsonValueType.kString
//        }else if (obj as AnyObject).className == "__NSCFNumber" {
//            return JsonValueType.kString
//        }else if (obj as AnyObject).className == "__NSCFBoolean" {
//            return JsonValueType.kString
//        }else if (obj as AnyObject).className == "JKDictionary" {
//            return JsonValueType.kString
//        }else if (obj as AnyObject).className == "__NSCFNumber" {
//            return JsonValueType.kString
//        }
        
        return JsonValueType.kOther
    }
    
    func typeName(_ type: JsonValueType) -> String {
        switch type {
        case .kString:
            return "String"
            
        case .kNumber:
            return "NSNumber"
            
//        case .kBool:
//            return "Bool"
            
        case .kArray, .kDictionary:
            return ""
            
        default:
            return "String"
//            break
        }
    }
    
    func uppercaseFirstChar(_ str: NSString) -> String {
        return "\(str.substring(to: 1).uppercased())\(str.substring(with: NSRange(location: 1, length: str.length - 1)))"
    }
    
    func lowercaseFirstChar(_ str: NSString) -> NSString {
        return "\(str.substring(to: 1).lowercased())\(str.substring(with: NSRange(location: 1, length: str.length - 1)))" as NSString
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

