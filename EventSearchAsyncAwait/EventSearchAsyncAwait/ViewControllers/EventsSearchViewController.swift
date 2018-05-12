//
//  EventsSearchViewController.swift
//  EventSearchAsyncAwait
//
//  Created by Yoshinori Imajo on 2018/05/12.
//  Copyright © 2018年 Yoshinori Imajo. All rights reserved.
//

import UIKit
import APIKit
import Hydra

struct Event {
    let title: String
    let service: Service

    enum Service: String {
        case atnd
        case connpass
    }
}

enum EventType {
    case atnd(AtndAPI.Event)
    case connpass(ConnpassAPI.Event)

    var title: String {
        switch self {
        case .atnd(let event):
            return event.title
        case .connpass(let event):
            return event.title
        }
    }

    var service: String {
        switch self {
        case .atnd:
            return "atnd"
        case .connpass:
            return "connpass"
        }
    }
}

let eventType = EventType.atnd(AtndAPI.Event(title: "title"))

class EventsSearchViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    var events = [AtndAPI.Event]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        // ConnpassとATNDから検索して
        // 両方の結果を待って
        // 検索結果を表示する

        async { _ -> ([AtndAPI.Event]) in
            print("async")
            let events = try await(self.searchAtnd(keyword: "swift"))
            print(events)

            return events

        }.then { events in
            self.events = events
            self.tableView.reloadData()
        }.catch { error in
            print(error)
        }

    }
}
extension EventsSearchViewController {

    func searchConnpass(keyword: String) -> Promise<[ConnpassAPI.Event]> {

        return Promise<[ConnpassAPI.Event]> { (resolve, reject, _) in

            let request = ConnpassAPI.SearchRequest(keyword: keyword)
            Session.send(request) { result in
                switch result {
                case .success(let response):
                    // 成功
                    print(response)
                    resolve(response.events)
                case .failure(let error):
                    // 失敗
                    reject(error)
                }
            }
        }
    }

    func searchAtnd(keyword: String) -> Promise<[AtndAPI.Event]> {

        return Promise<[AtndAPI.Event]> { (resolve, reject, _) in

            let request = AtndAPI.SearchRequest(keyword: keyword)
            Session.send(request) { result in
                switch result {
                case .success(let response):
                    // 成功
                    print(response)
                    resolve(response.events.map { $0.event })
                case .failure(let error):
                    // 失敗
                    reject(error)
                }
            }
        }
    }
}
extension EventsSearchViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return events.count

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel?.text = events[indexPath.row].title
        return cell
    }
}
