//
//  ClientAPI.swift
//  TorrentAdder
//
//  Created by Stanislas Chevallier on 03/12/2018.
//  Copyright © 2018 Syan. All rights reserved.
//

import UIKit
import BrightFutures
import Alamofire
import Fuzi

class ClientAPI: NSObject {

    // MARK: Init
    static let shared = ClientAPI()
    
    override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        super.init()
        session = Alamofire.Session(configuration: configuration, interceptor: self)
    }
    
    // MARK: Properties
    private var session: Session!
    private var pendingAuthentications = [String: [(RetryResult) -> Void]]()
    private var transmissionSessionIDs = [String: String]()
    
    // MARK: Public methods
    func getClientStatus(_ client: Client) -> Future<Bool, Never> {
        return session.request(client.apiURL)
            .validate()
            .responseFutureData()
            .map { _ in true }
            .recover { error in
                if case let .alamofire(afError) = error, afError.response != nil {
                    return true
                }
                return false
        }
    }
    
    func addMagnet(_ magnetURL: URL, to client: Client) -> Future<String?, AppError> {
        switch client.software {
        case .transmission:
            return self.addMagnet(magnetURL, toTransmission: client)
        case .uTorrent:
            return self
                .getUTorrentToken(client)
                .flatMap { token in self.addMagnet(magnetURL, toUTorrent: client, token: token)}
        }
    }
    
    func removeCompletedTorrents(in client: Client) -> Future<Int, AppError> {
        switch client.software {
        case .transmission:
            return self
                .listEndedTorrents(inTransmission: client)
                .flatMap { ids in self.removeTorrents(ids: ids, fromTransmission: client) }
            
        case .uTorrent:
            var token: String = ""
            return self
                .getUTorrentToken(client)
                .onSuccess { t in token = t }
                .map { t -> String in token = t; return t }
                .flatMap { _ in self.listEndedTorrents(inUTorrent: client, token: token) }
                .flatMap { hashes in self.removeTorrent(hashes: hashes, fromUTorrent: client, token: token) }
        }
    }
}

private extension ClientAPI {
    // MARK: Transmission
    // https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt
    // https://github.com/transmission/transmission/blob/1.70/doc/rpc-spec.txt
    
    private struct TransmissionResponse: Decodable {
        struct Item : Decodable {
            let id: Int
            let doneDate: Int
            let name: String
        }
        
        let result: String
        let items: [Item]
        
        private enum CodingKeys: String, CodingKey {
            case result = "result", arguments = "arguments"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            result = try container.decode(String.self, forKey: .result)
            
            if let arguments = try? container.decode([String: [Item]].self, forKey: .arguments) {
                items = arguments["torrents"] ?? []
            }
            else {
                items = []
            }
        }
    }

    private func addMagnet(_ magnetURL: URL, toTransmission client: Client) -> Future<String?, AppError> {
        let parameters: Parameters = [
            "method":"torrent-add",
            "arguments": ["filename": magnetURL.absoluteString]
            ]
            
        return session
            .request(client.apiURL, method: HTTPMethod.post, parameters: parameters, encoding: JSONEncoding(), headers: nil)
            .validate()
            .responseFutureCodable(type: TransmissionResponse.self)
            .map { $0.result }
    }
    
    private func listEndedTorrents(inTransmission client: Client) -> Future<[Int], AppError> {
        let parameters: Parameters = [
            "method":"torrent-get",
            "arguments": ["fields": ["id", "doneDate", "name"]]
        ]
        
        return session
            .request(client.apiURL, method: HTTPMethod.post, parameters: parameters, encoding: JSONEncoding(), headers: nil)
            .validate()
            .responseFutureCodable(type: TransmissionResponse.self)
            .map { response in response.items.filter { $0.doneDate > 0 }.map { $0.id } }
    }
    
    private func removeTorrents(ids: [Int], fromTransmission client: Client) -> Future<Int, AppError> {
        guard !ids.isEmpty else { return Future<Int, AppError>(value: 0) }
        
        let parameters: Parameters = [
            "method":"torrent-remove",
            "arguments": ["ids": ids, "delete-local-data": false]
        ]
        
        return session
            .request(client.apiURL, method: HTTPMethod.post, parameters: parameters, encoding: JSONEncoding(), headers: nil)
            .validate()
            .responseFutureCodable(type: TransmissionResponse.self)
            .map { _ in ids.count }
    }
}

private extension ClientAPI {
    // MARK: uTorrent
    // http://stackoverflow.com/questions/22079581/utorrent-api-add-url-giving-400-invalid-request
    // http://forum.utorrent.com/topic/21814-web-ui-api/#entry207447
    // http://forum.utorrent.com/topic/49588-%C2%B5torrent-webui/
    
    private struct UTorretResponse: Decodable {
        struct Item: Decodable {
            let hash: String
            let name: String
            let permils: Int
            let remainingBytes: Int

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let array = try container.decode([JSONValue].self)
                let anyArray = array.map { $0.value }
                
                // http://help.utorrent.com/customer/en/portal/articles/1573947-torrent-labels-list---webapi
                guard let hash           = anyArray.element(at:  0) as? String else { throw AppError.invalidUTorrentPayload }
                guard let name           = anyArray.element(at:  2) as? String else { throw AppError.invalidUTorrentPayload }
                guard let permils        = anyArray.element(at:  4) as? Int    else { throw AppError.invalidUTorrentPayload }
                guard let remainingBytes = anyArray.element(at: 18) as? Int    else { throw AppError.invalidUTorrentPayload }

                self.hash = hash
                self.name = name
                self.permils = permils
                self.remainingBytes = remainingBytes
            }
            
            var isFinished: Bool { return permils == 1000 && remainingBytes == 0 }
        }
        
        let torrents: [Item]
        
        private enum CodingKeys: String, CodingKey {
            case torrents = "torrents"
        }
    }
    

    private func getUTorrentToken(_ client: Client) -> Future<String, AppError> {
        return session
            .request(client.apiURL.appendingPathComponent("token.html"))
            .validate()
            .responseFutureHTML()
            .flatMap { html -> Future<String, AppError> in
                if let token = html.firstChild(css: "div#token")?.text {
                    return Future(value: token)
                }
                return Future(error: AppError.noUTorrentToken)
        }
    }
    
    private func addMagnet(_ magnetURL: URL, toUTorrent client: Client, token: String) -> Future<String?, AppError> {
        let parameters: Parameters = [
            "token": token,
            "action": "add-url",
            "s": magnetURL.absoluteString
        ]
        
        return session
            .request(client.apiURL, parameters: parameters, encoding: URLEncoding(), headers: nil)
            .validate()
            .responseFutureJSON()
            .map { json in nil }
    }
    
    private func listEndedTorrents(inUTorrent client: Client, token: String) -> Future<[String], AppError> {
        let parameters: Parameters = [
            "token": token,
            "list": 1
        ]
        
        return session
            .request(client.apiURL, parameters: parameters, encoding: URLEncoding(), headers: nil)
            .validate()
            .responseFutureCodable(type: UTorretResponse.self)
            .map { response in response.torrents.filter { $0.isFinished }.map { $0.hash } }
    }
    
    private func removeTorrent(hashes: [String], fromUTorrent client: Client, token: String) -> Future<Int, AppError> {
        guard !hashes.isEmpty else { return Future<Int, AppError>(value: 0) }
        
        return hashes
            .map { self.removeTorrent(hash: $0, fromUTorrent: client, token: token) }
            .sequence()
            .map { _ in hashes.count }
    }

    private func removeTorrent(hash: String, fromUTorrent client: Client, token: String) -> Future<(), AppError> {
        let parameters: Parameters = [
            "token": token,
            "action": "remove",
            "hash": hash
        ]

        return session
            .request(client.apiURL, parameters: parameters, encoding: URLEncoding(), headers: nil)
            .validate()
            .responseFutureJSON()
            .map { _ in () }
    }
}

extension ClientAPI : RequestInterceptor {
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard let client = urlRequest.client else { return completion(.success(urlRequest)) }

        var request = urlRequest
        if let u = client.username, let p = client.password, let base64 = "\(u):\(p)".data(using: .utf8)?.base64EncodedString() {
            request.setValue("Basic " + base64, forHTTPHeaderField: "Authorization")
        }
        if let sessionID = transmissionSessionIDs[client.id] {
            request.setValue(sessionID, forHTTPHeaderField: "X-Transmission-Session-Id")
        }
        completion(.success(request))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let client = request.request?.client, request.retryCount < 5 else {
            completion(.doNotRetry)
            return
        }
        
        if client.software == .transmission, request.response?.statusCode == 409,
            let sessionID = request.response?.allHeaderFields["X-Transmission-Session-Id"] as? String
        {
            transmissionSessionIDs[client.id] = sessionID
            completion(.retryWithDelay(0.1))
            return
        }

        if request.response?.statusCode == 401 {
            if pendingAuthentications.keys.contains(client.id) {
                pendingAuthentications[client.id]?.append(completion)
                return
            }
            
            pendingAuthentications[client.id] = [completion]

            DispatchQueue.main.async {
                ViewRouter.shared.promptAuthenticationUpdate(for: client) { (cancelled) in
                    let completions = self.pendingAuthentications[client.id] ?? []
                    self.pendingAuthentications.removeValue(forKey: client.id)
                    
                    if cancelled {
                        completions.forEach { $0(.doNotRetry) }
                    }
                    else {
                        completions.forEach { $0(.retryWithDelay(0.1)) }
                    }
                }
            }
            return
        }
        
        completion(.doNotRetry)
    }
}

