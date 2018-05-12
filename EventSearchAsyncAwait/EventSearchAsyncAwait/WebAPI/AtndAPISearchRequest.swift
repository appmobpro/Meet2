//
//  AtndAPISearchRequest.swift
//  EventSearchAsyncAwait
//
//  Created by Yoshinori Imajo on 2018/05/12.
//  Copyright © 2018年 Yoshinori Imajo. All rights reserved.
//

import Foundation
import APIKit

struct AtndAPI {

    struct EventResoponse: Decodable {
        let events: [AtndAPI.EventSakamoto]
    }

    struct EventSakamoto: Decodable {
        let event: Event
    }

    struct Event: Decodable {
        let title: String
        let event_url: String
    }
}

// MARK: - APIKit

protocol AtndRequest: Request { }

extension AtndRequest where Response: Decodable {
    var dataParser: DataParser {
        return DecodableDataParser()
    }
}



extension AtndAPI {

    struct SearchRequest: AtndRequest {
        typealias Response = EventResoponse

        let keyword: String

        let method = HTTPMethod.get

        let baseURL = URL(string: "https://api.atnd.org")!

        let path = "/events"


        var parameters: Any? {
            return ["keyword": keyword, "ym": "201805", "format": "json"]
        }

        func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {

            guard let data = object as? Data else {
                throw ResponseError.unexpectedObject(object)
            }
            return try JSONDecoder().decode(Response.self, from: data)
        }
    }
}



