//
//  TransformUtils.swift
//  iOSFramework
//
//  Created by Mr Mac on 2024/1/2.
//

import Foundation

struct TransformUtils {

    static func dictToJson(dict:[String:Any]) -> String?{
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])

            // 将 JSON 数据转换为字符串
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("JSON 字符串: \(jsonString)")
                return jsonString
            }
        } catch {
            print("转换为 JSON 字符串时出错: \(error)")
            return nil
        }
        return nil
    }

    static func convertToStruct(from string: String)-> SocketInfo?{
        guard let jsonData = string.data(using: .utf8) else {
            print("无法将字符串转换为数据")
            return nil
        }

        do {
            let person = try JSONDecoder().decode(SocketInfo.self, from: jsonData)
            return person
        } catch {
            print("解析 JSON 失败：\(error.localizedDescription)")
            return nil
        }
    }

    static func convertToDictionary(from text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print("转换失败：\(error.localizedDescription)")
            }
        }
        return nil
    }
}
