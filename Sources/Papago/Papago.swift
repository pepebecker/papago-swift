//
//  Papago.swift
//  Papago
//
//  Created by Pepe Becker on 2023/02/05.
//

import Foundation

public class Papago {

  public struct Config {
    var clientId: String
    var clientSecret: String
  }

  public enum Language: String, CaseIterable {
    case auto = "auto"
    case en = "en"
    case ko = "ko"
    case ja = "ja"
    case zhCN = "zh-CN"
    case zhTW = "zh-TW"
    case es = "es"
    case fr = "fr"
    case de = "de"
    case ru = "ru"
    case pt = "pt"
    case it = "it"
    case vi = "vi"
    case th = "th"
    case id = "id"
    case hi = "hi"
  }

  public static func targetLanguagues(for source: Language) -> [Language] {
    let languages = Language.allCases
    switch source {
    case .auto:
      return []
    case .ko:
      return [.en, .ja, .zhCN, .zhTW, .es, .fr, .de, .ru, .it, .vi, .th, .id]
    case .ja:
      return [.en, .ko, .zhCN, .zhTW, .fr, .vi, .th, .id]
    case .zhCN:
      return [.en, .ko, .ja, .zhTW]
    case .zhTW:
      return [.en, .ko, .ja, .zhCN]
    case .es:
      return [.en, .ko]
    case .fr:
      return [.en, .ko, .ja]
    case .de:
      return [.en, .ko]
    case .ru:
      return [.en, .ko]
    default:
      return languages.filter { $0 != .auto && $0 != source }
    }
  }

  public static func targetLanguagues(for source: String) -> [Language] {
    if let lang = parseLanguage(source) {
      return targetLanguagues(for: lang)
    }
    return []
  }

  public static func parseLanguage(_ lang: String?) -> Language? {
    guard let lang = lang else { return nil }
    if lang.lowercased() == "zh-cn" || lang.lowercased() == "zh-hans" {
      return .zhCN
    }
    if lang.lowercased() == "zh-tw" || lang.lowercased() == "zh-hant" {
      return .zhTW
    }
    return Language.allCases.first(where: { lang.lowercased().contains($0.rawValue.lowercased()) })
  }

  internal static func parseJSON(data: Data) -> [String: Any]? {
    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
      return json
    }
    return nil
  }

  internal static func parseError(data: Data) -> Error? {
    if let json = parseJSON(data: data), let message = json["errorMessage"] as? String {
      return NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
    let message = String(decoding: data, as: UTF8.self)
    return NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
  }

  private(set) var config: Config? = nil

  public init(config: Config) {
    self.config = config
  }

  public convenience init() {
    var clientId = ProcessInfo.processInfo.environment["TEXT_CAPTURE_PAPAGO_CLIENT_ID"]
    var clientSecret = ProcessInfo.processInfo.environment["TEXT_CAPTURE_PAPAGO_CLIENT_SECRET"]
    if clientId == nil && clientSecret == nil {
      clientId = ProcessInfo.processInfo.environment["PAPAGO_CLIENT_ID"]
      clientSecret = ProcessInfo.processInfo.environment["PAPAGO_CLIENT_SECRET"]
    }
    if clientId == nil && clientSecret == nil {
      clientId = ProcessInfo.processInfo.environment["NAVER_CLIENT_ID"]
      clientSecret = ProcessInfo.processInfo.environment["NAVER_CLIENT_SECRET"]
    }
    self.init(config: Config(clientId: clientId ?? "", clientSecret: clientSecret ?? ""))
  }

  internal func buildBody(text: String, source: Language, target: Language, honorific: Bool? = nil) -> String {
    var components = URLComponents()
    components.queryItems = [
      URLQueryItem(name: "source", value: source.rawValue),
      URLQueryItem(name: "target", value: target.rawValue),
      URLQueryItem(name: "text", value: text),
    ]
    if let honorific = honorific {
      components.queryItems?.append(URLQueryItem(name: "honorific", value: String(honorific)))
    }
    return components.percentEncodedQuery ?? ""
  }

  public func translate(text: String, from: Language, to: Language, honorific: Bool?, done: @escaping (String?, Error?) -> Void) {
    guard let clientId = config?.clientId, !clientId.isEmpty else {
      done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "NAVER_CLIENT_ID is not set"]))
      return
    }
    guard let clientSecret = config?.clientSecret, !clientSecret.isEmpty else {
      done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "NAVER_CLIENT_SECRET is not set"]))
      return
    }
    if text.isEmpty {
      done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "There is no text to translate"]))
      return
    }

    let body = buildBody(text: text, source: from, target: to, honorific: honorific)

    let url = URL(string: "https://openapi.naver.com/v1/papago/n2mt")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "content-type")
    request.setValue(clientId, forHTTPHeaderField: "x-naver-client-id")
    request.setValue(clientSecret, forHTTPHeaderField: "x-naver-client-secret")
    request.httpBody = body.data(using: .utf8)

    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      if let error = error {
        done(nil, error)
        return
      }
      guard let response = response as? HTTPURLResponse else {
        done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "No response"]))
        return
      }
      guard (200...299).contains(response.statusCode) else {
        if let data = data, let error = Self.parseError(data: data) {
          done(nil, error)
        } else if response.statusCode == 429 {
          done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "Too many requests"]))
        } else {
          let text = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
          let message = "Bad status code: \(response.statusCode) \(text)\n"
          done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        }
        return
      }
      guard let data = data else {
        done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
        return
      }
      guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
        done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse JSON"]))
        return
      }
      guard let message = json["message"] as? [String: Any] else {
        done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find message in JSON \n\(json)"]))
        return
      }
      guard let result = message["result"] as? [String: Any] else {
        done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find result in JSON"]))
        return
      }
      if let translation = result["translatedText"] as? String {
        done(translation, nil)
      } else {
        done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find translatedText in JSON"]))
      }
    }
    task.resume()
  }

  public func translate(text: String, from: String?, to: String?, honorific: Bool?, done: @escaping (String?, Error?) -> Void) {
    guard let source = Self.parseLanguage(from) else {
      done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid source language"]))
      return
    }
    guard let target = Self.parseLanguage(to) else {
      done(nil, NSError(domain: "Papago", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid target language"]))
      return
    }
    translate(text: text, from: source, to: target, honorific: honorific, done: done)
  }

}
