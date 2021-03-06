//
//  SearchResult.swift
//  TorrentAdder
//
//  Created by Stanislas Chevallier on 30/11/2018.
//  Copyright © 2018 Syan. All rights reserved.
//

import UIKit
import Fuzi

struct SearchResult : Decodable {

    // MARK: Properties
    let id: String
    let name: String
    let infoHash: String
    let seeders: Int
    let leechers: Int
    let size: Int64
    let verified: Bool
    let added: Date

    // MARK: Decodable
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case infoHash = "info_hash"
        case seeders = "seeders"
        case leechers = "leechers"
        case size = "size"
        case status = "status"
        case added = "added"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        infoHash = try container.decode(String.self, forKey: .infoHash)
        seeders = Int(try container.decode(String.self, forKey: .seeders)) ?? 0
        leechers = Int(try container.decode(String.self, forKey: .leechers)) ?? 0
        size = Int64(try container.decode(String.self, forKey: .size)) ?? 0
        verified = (try container.decode(String.self, forKey: .status)) == "trusted"
        added = Date(timeIntervalSince1970: TimeInterval(Int((try container.decode(String.self, forKey: .added))) ?? 0))
    }
}

extension SearchResult {
    func pageURL(mirror: URL) -> URL {
        var components = URLComponents(url: mirror, resolvingAgainstBaseURL: true)!
        components.path = "/description.php"
        components.queryItems = [URLQueryItem(name: "id", value: id)]
        return components.url!
    }

    var magnetURL: URL {
        var components = URLComponents()
        components.scheme = "magnet"
        components.queryItems = [
            URLQueryItem(name: "xt", value: "urn:btih:" + infoHash),
            URLQueryItem(name: "dn", value: name),
            URLQueryItem(name: "tr", value: "udp://tracker.coppersurfer.tk:6969/announce"),
            URLQueryItem(name: "tr", value: "udp://9.rarbg.to:2920/announce"),
            URLQueryItem(name: "tr", value: "udp://tracker.opentrackr.org:1337"),
            URLQueryItem(name: "tr", value: "udp://tracker.internetwarriors.net:1337/announce"),
            URLQueryItem(name: "tr", value: "udp://tracker.leechers-paradise.org:6969/announce"),
            URLQueryItem(name: "tr", value: "udp://tracker.coppersurfer.tk:6969/announce"),
            URLQueryItem(name: "tr", value: "udp://tracker.pirateparty.gr:6969/announce"),
            URLQueryItem(name: "tr", value: "udp://tracker.cyberia.is:6969/announce"),
        ]

        return components.url!
    }
}

extension SearchResult : CustomStringConvertible {
    var description: String {
        return "Result: \(name), \(size), \(added), \(seeders)/\(leechers), vip=\(verified)"
    }
}
