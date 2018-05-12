//
//  ConnpassAPISearchRequest.swift
//  EventSearchAsyncAwait
//
//  Created by Yoshinori Imajo on 2018/05/12.
//  Copyright © 2018年 Yoshinori Imajo. All rights reserved.
//

import Foundation
import APIKit

struct ConnpassAPI {

    struct EventResoponse: Decodable {
        let events: [ConnpassAPI.Event]
    }

    struct Event: Decodable {
        let title: String
    }
}

// MARK: - APIKit

protocol ConnpassRequest: Request { }

extension ConnpassRequest where Response: Decodable {
    var dataParser: DataParser {
        return DecodableDataParser()
    }
}

final class DecodableDataParser: DataParser {
    var contentType: String? {
        return "application/json"
    }

    func parse(data: Data) throws -> Any {
        return data
    }
}

extension ConnpassAPI {

    struct SearchRequest: ConnpassRequest {
        typealias Response = EventResoponse

        let keyword: String

        var method: HTTPMethod {
            return .get
        }

        let baseURL = URL(string: "https://connpass.com/api/v1")!

        var path: String {
            return "/event"
        }

        var parameters: Any? {
            return ["keyword": keyword, "ym": "201805"]
        }

        func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {

            guard let data = object as? Data else {
                throw ResponseError.unexpectedObject(object)
            }
            return try JSONDecoder().decode(Response.self, from: data)
        }
    }
}

//let reqeust = ConnpassAPI.SearchRequest()
//Session.send(request) { result in
//    switch result {
//    case .success(let event):
//        // 成功
//    case .failure(let error):
//        // 失敗
//        print("error: \(error)")
//    }
//}





