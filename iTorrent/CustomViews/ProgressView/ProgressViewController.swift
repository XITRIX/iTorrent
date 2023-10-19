//
//  ProgressViewController.swift
//  iTorrent
//
//  Created by Magesh K on 19/10/23.
//  Copyright © 2023 Magesh K. All rights reserved.
//

import Foundation
import UIKit

class ProgressViewController: UIViewController {
    private let progressView = UIActivityIndicatorView(style: .whiteLarge)
    private let progressLabel = ThemedUILabel()
    private var progress:Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7) // Semi-transparent background
        
        // Do not perform autolayout
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        view.addSubview(progressLabel)
        
        progressView.hidesWhenStopped = true
        
        // explicit layout constraints
        NSLayoutConstraint.activate([
            // center the progressView on parent view
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // place the progress label below the progressView with constant space between the two
            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8), // Adjust the spacing as needed
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        progressLabel.textColor = .white
        // progressLabel.font = UIFont.systemFont(ofSize: 16)                // Adjust the size
        // progressLabel.font = UIFont.boldSystemFont(ofSize: 16)
        progressLabel.font = UIFont(name: "Helvetica-Bold", size: 16)
        progressLabel.backgroundColor = .clear
        
        progressView.startAnimating() // Start the activity indicator
    }
    
    public func runSyncOnUIThread(action: ()->Void){
        if (Thread.isMainThread){ action() }
        else { DispatchQueue.main.sync { action() } }
    }

    public func showProgress(presenter: UIViewController?, animated: Bool=true, action: (()->Void)? = nil) {
        runSyncOnUIThread{
            progressLabel.text = "0.00%"
            modalPresentationStyle  = .overFullScreen
            modalTransitionStyle    = .crossDissolve
            presenter?.present(self, animated: animated, completion: action)
        }
    }
    
    public func hideProgress(animated: Bool=true, action: (()->Void)? = nil) {
        runSyncOnUIThread{
            dismiss(animated: animated, completion: action)
        }
    }
    
    public func setProgress(_ progress: Float) {
        // Keep progress updates synchronously on UI Thread
        runSyncOnUIThread {
            self.progress = progress
            // cap the progress at 100%
            if(progress > 100.0){ self.progress = 100.0 }
            self.progressLabel.text = String(format: "%.2f%%", self.progress)
        }
    }
    
    public func getProgress()->Float{
        return self.progress
    }
    
    public func consumeRemainingPercentage(){
        var totalProgress = self.progress
        let increment:Float = 1.0
        while(totalProgress <= 100.0){
            totalProgress += increment          // increment the progress
            setProgress(totalProgress)
        }
    }
}
