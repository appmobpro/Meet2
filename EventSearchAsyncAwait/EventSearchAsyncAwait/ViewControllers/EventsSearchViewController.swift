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

    var eventURL: URL {
        switch self {
        case .atnd(let event):
            return URL(string: event.event_url)!
        case .connpass(let event):
            return URL(string: event.event_url)!
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

class EventsSearchViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    let cache = NSCache<NSString, NSString>()
    var events = [EventType]() {
        didSet {
            async(in: .main) { self.tableView.reloadData() }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        // ConnpassとATNDから検索して
        // 両方の結果を待って
        // 検索結果を表示する

    }
    
}

extension EventsSearchViewController {

    func searchConnpass(keyword: String) -> Promise<[ConnpassAPI.Event]> {
        print("-- search connpass --")

        return Promise<[ConnpassAPI.Event]> { (resolve, reject, _) in

            let request = ConnpassAPI.SearchRequest(keyword: keyword)
            Session.send(request) { result in
                switch result {
                case .success(let response):
                    // 成功
                    print("-- success connpass --")
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
        print("-- search atnd --")

        return Promise<[AtndAPI.Event]> { (resolve, reject, _) in

            let request = AtndAPI.SearchRequest(keyword: keyword)
            Session.send(request) { result in
                switch result {
                case .success(let response):
                    // 成功
                    print("-- success atnd --")
                    print(response)
                    resolve(response.events.map { $0.event })
                case .failure(let error):
                    // 失敗
                    reject(error)
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goDetail" {
            let selectedIndex = tableView.indexPathForSelectedRow!
            let url = events[selectedIndex.row].eventURL
            let urlString = events[selectedIndex.row].eventURL.absoluteString as NSString
            let html = cache.object(forKey: urlString)!
            let vc = segue.destination as! DetailViewController
            vc.loadViewIfNeeded()
            vc.webView.loadHTMLString(String(html), baseURL:url.baseURL)
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
        cell.detailTextLabel?.text = events[indexPath.row].service

        return cell
    }
}

extension EventsSearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        async { _ in
            print("async")

            let (atndEvents, connpassEvents) = try await(Promise<Void>.zip(
                self.searchAtnd(keyword: searchText),
                self.searchConnpass(keyword: searchText)
            ))

            let events: [EventType] = atndEvents.map { .atnd($0) } + connpassEvents.map { .connpass($0) }

            self.events = events
            
            let promises = events.map(getHtml)
            let htmlTexts = try await(all(promises, concurrency: 4))
            htmlTexts.forEach { (html, url) in
                self.cache.setObject(html as NSString, forKey: url as NSString)
            }
        }.catch { error in
            print(error)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
}

private func getHtml(event: EventType) -> Promise <(html: String, url: String)> {
    return Promise { resolve, reject, _ in
        guard let text = try? String(contentsOf: event.eventURL) else {
            reject(fatalError() as! Error) }
        resolve((text, event.eventURL.absoluteString))
    }
}

extension EventsSearchViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBar.endEditing(true)
    }
}
