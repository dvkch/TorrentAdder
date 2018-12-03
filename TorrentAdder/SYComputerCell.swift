//
//  SYComputerCell.swift
//  TorrentAdder
//
//  Created by Stanislas Chevallier on 28/11/2018.
//  Copyright © 2018 Syan. All rights reserved.
//

import UIKit

class SYComputerCell: UITableViewCell {
    // TODO: cleanup computer everywhere!
    
    // MARK: Init
    override func awakeFromNib() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateStatus), name: .clientStatusChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .clientStatusChanged, object: nil)
    }
    
    // MARK: Properties
    var isDiscoveredClient: Bool = false {
        didSet {
            updateContent()
            updateStatus()
        }
    }
    var client: SYClient? {
        didSet {
            updateContent()
            updateStatus()
        }
    }
    
    // MARK: Views
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var hostLabel: UILabel!
    @IBOutlet private var statusImageView: UIImageView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Content
    private func updateContent() {
        accessoryType = isDiscoveredClient ? .disclosureIndicator : .none
        if let client = client {
            nameLabel.text = client.name
            if isDiscoveredClient {
                hostLabel.text = client.host
            }
            else {
                hostLabel.text = [client.host, String(client.port ?? 0)].joined(separator: ":")
            }
        }
        else if isDiscoveredClient
        {
            nameLabel.text = "Add a custom computer"
            hostLabel.text = "in case yours wasn't detected"
        }
        else
        {
            nameLabel.text = nil
            hostLabel.text = nil
        }
    }
    
    @objc private func updateStatus() {
        var loading = SYClientStatusManager.shared.isClientLoading(client)
        var status  = SYClientStatusManager.shared.lastStatusForClient(client)
        
        if isDiscoveredClient && client == nil {
            loading = true
        }
        if isDiscoveredClient && client != nil {
            status = .online
        }
        
        // show loading only if previous status is unknown, else show last status
        if loading && status == .unknown {
            statusImageView.image = nil
            activityIndicator.startAnimating()
            return
        }
        
        switch status {
        case .online:
            statusImageView.image = UIImage(named: "traffic_green")
            activityIndicator.stopAnimating()
        case .offline:
            statusImageView.image = UIImage(named: "traffic_grey")
            activityIndicator.stopAnimating()
        case .unknown:
            statusImageView.image = nil
            activityIndicator.stopAnimating()
        }
    }
}
