//
//  CameraViewController.swift
//  LivePhotoToVideo
//
//  Created by Bradley GIlmore on 4/12/19.
//  Copyright © 2019 Bradley Gilmore. All rights reserved.
//

import UIKit
import AVFoundation
import WebKit
import SwiftyCam

class CameraViewController: SwiftyCamViewController {

    //MARK: - IBOutlets
    
    @IBOutlet weak var captureButton: SwiftyRecordButton!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    
    var webView = WKWebView()
    let webViewXButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    var hasLoadedWebView = false
    
    //MARK: - Status Bar
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shouldPrompToAppSettings = true
        cameraDelegate = self
        maximumVideoDuration = 10.0
        shouldUseDeviceOrientation = true
        allowAutoRotate = true
        audioEnabled = true
        flashMode = .auto
        flashButton.setImage(#imageLiteral(resourceName: "flashauto"), for: UIControl.State())
        captureButton.buttonEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureButton.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        do{
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .allowBluetooth, .allowAirPlay, .allowBluetoothA2DP, .defaultToSpeaker])
            } else {
                let options: [AVAudioSession.CategoryOptions] = [.mixWithOthers, .allowBluetooth, .defaultToSpeaker]
                let category = AVAudioSession.Category.playAndRecord
                let selector = NSSelectorFromString("setCategory:withOptions:error:")
                AVAudioSession.sharedInstance().perform(selector, with: category, with: options)
            }
            try AVAudioSession.sharedInstance().setActive(true)
            session.automaticallyConfiguresApplicationAudioSession = false
        }
        catch {
            print("[SwiftyCam]: Failed to set background audio preference")
            
        }

    }
    
    //MARK: - IBActions
    
    @IBAction func cameraSwitchTapped(_ sender: Any) {
        switchCamera()
    }
    
    @IBAction func toggleFlashTapped(_ sender: Any) {
        toggleFlashAnimation()
    }
    
    @IBAction func musicIconTapped(_ sender: Any) {
        loadWebView()
    }
    
    func loadWebView() {
        
        if !hasLoadedWebView {
            let webConfiguration = WKWebViewConfiguration()
            webConfiguration.allowsInlineMediaPlayback = true
            webConfiguration.mediaTypesRequiringUserActionForPlayback = []
            
            webView = WKWebView(frame: CGRect(x: self.view.frame.minX, y: self.view.frame.minY + 40, width: self.view.frame.width, height: self.view.frame.height - 40), configuration: webConfiguration)
            self.view.addSubview(webView)
            
            if let videoURL:URL = URL(string: "https://music.youtube.com/") {
                let request:URLRequest = URLRequest(url: videoURL)
                webView.load(request)
            }
            
            webViewXButton.setImage(UIImage(named: "closeIcon"), for: .normal)
            webViewXButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
            
            self.view.addSubview(webViewXButton)
            self.view.addSubview(webView)
            
            // Hide Camera Stuff
            flipCameraButton.isHidden = !flipCameraButton.isHidden
            flashButton.isHidden = !flashButton.isHidden
            
            hasLoadedWebView = true
        } else {
            toggleHideWebView()
        }
    }
    
    @objc func buttonAction() {
        toggleHideWebView()
    }
    
    func toggleHideWebView() {
        
        // Web View
        webView.isHidden = !webView.isHidden
        webViewXButton.isHidden = !webViewXButton.isHidden
        
        if hasLoadedWebView {
            // Camera Stuff
            flipCameraButton.isHidden = !flipCameraButton.isHidden
            flashButton.isHidden = !flashButton.isHidden
        }
    }
    
}

//MARK: - SwiftyCamViewControllerDelegate Related

extension CameraViewController: SwiftyCamViewControllerDelegate {
    
    func swiftyCamSessionDidStartRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did start running")
        captureButton.buttonEnabled = true
    }
    
    func swiftyCamSessionDidStopRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did stop running")
        captureButton.buttonEnabled = false
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        let newVC = PhotoViewController(image: photo)
        self.present(newVC, animated: true, completion: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did Begin Recording")
        captureButton.growButton()
        hideButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did finish Recording")
        captureButton.shrinkButton()
        showButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        let newVC = VideoViewController(videoURL: url)
        self.present(newVC, animated: true, completion: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        print("Did focus at point: \(point)")
        focusAnimationAt(point)
    }
    
    func swiftyCamDidFailToConfigure(_ swiftyCam: SwiftyCamViewController) {
        let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        print("Zoom level did change. Level: \(zoom)")
        print(zoom)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        print("Camera did change to \(camera.rawValue)")
        print(camera)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFailToRecordVideo error: Error) {
        print(error)
    }
    
}


//MARK: - UI Animations
extension CameraViewController {
    
    fileprivate func hideButtons() {
        UIView.animate(withDuration: 0.25) {
            self.flashButton.alpha = 0.0
            self.flipCameraButton.alpha = 0.0
        }
    }
    
    fileprivate func showButtons() {
        UIView.animate(withDuration: 0.25) {
            self.flashButton.alpha = 1.0
            self.flipCameraButton.alpha = 1.0
        }
    }
    
    fileprivate func focusAnimationAt(_ point: CGPoint) {
        let focusView = UIImageView(image: #imageLiteral(resourceName: "focus"))
        focusView.center = point
        focusView.alpha = 0.0
        view.addSubview(focusView)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }) { (success) in
                focusView.removeFromSuperview()
            }
        }
    }
    
    fileprivate func toggleFlashAnimation() {
        //flashEnabled = !flashEnabled
        if flashMode == .auto{
            flashMode = .on
            flashButton.setImage(#imageLiteral(resourceName: "flash"), for: UIControl.State())
        }else if flashMode == .on{
            flashMode = .off
            flashButton.setImage(#imageLiteral(resourceName: "flashOutline"), for: UIControl.State())
        }else if flashMode == .off{
            flashMode = .auto
            flashButton.setImage(#imageLiteral(resourceName: "flashauto"), for: UIControl.State())
        }
    }
}

extension WKWebView {
    func load(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            load(request)
        }
    }
}
