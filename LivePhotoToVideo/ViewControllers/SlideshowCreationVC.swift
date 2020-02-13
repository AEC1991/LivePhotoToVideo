//
//  SlideshowCreationVC.swift
//  LivePhotoToVideo
//
//  Created by Murphy Brantley on 9/21/18.
//  Copyright © 2018 Murphy Brantley. All rights reserved.
//


import UIKit
import Photos
import PhotosUI
import MobileCoreServices
import AVKit
import AVFoundation
import SafariServices
import StoreKit

class SlideshowCreationVC: UIViewController {
    
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var placeholderView: UIView!
    
    //var livePhotoAsset: PHAsset?
    var imageAssets = [PHAsset]()
    var finalImageArray = [UIImage]()
    // var photoView: PHLivePhotoView!
    var gifURL: URL?
    @IBOutlet weak var exportShareButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var avPlayer: AVPlayer!
    
    var progressMeterContainer: UIView?
    var progressMeter: UIView?
    var progressCompleteLabel = UILabel()
    
    var activityIndicator = UIActivityIndicatorView()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.exportShareButton.isEnabled = false
        
        self.view.backgroundColor = UIColor.black
        UIApplication.shared.isStatusBarHidden = true
        
        createProgressMeter()
        
        self.view.addSubview(activityIndicator)
        activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.center = self.view.center
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        
        self.view.bringSubviewToFront(exportShareButton)
        self.view.bringSubviewToFront(backButton)
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // configureView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // create the image array, which will then generate the slideshow
        self.generateMultipleImageSingleAudioVideo2()

    }
    
    func createProgressMeter() {
        progressMeterContainer = UIView(frame: CGRect(x: 50, y: 60, width: self.view.frame.size.width - 100, height: 5))
        progressMeterContainer?.clipsToBounds = true
        progressMeterContainer?.layer.cornerRadius = (progressMeterContainer?.frame.size.height)! / 2
        progressMeterContainer?.backgroundColor = UIColor.darkGray
        self.view.addSubview(progressMeterContainer!)
        
        progressMeter = UIView(frame: CGRect(x: 50, y: 60, width: 0, height: 5))
        progressMeter?.clipsToBounds = true
        progressMeter?.layer.cornerRadius = (progressMeter?.frame.size.height)! / 2
        progressMeter?.backgroundColor = UIColor.white
        self.view.addSubview(progressMeter!)
        
        //progressCompleteLabel = UILabel(frame: CGRect(x: 16, y: 30, width: self.view.frame.size.width - 32, height: 24))
        //        progressCompleteLabel.center = CGPoint(x: self.view.center.x, y: (progressMeterContainer?.frame.origin.y)! + 24)
        progressCompleteLabel.textAlignment = .center
        progressCompleteLabel.textColor = .white
        progressCompleteLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        progressCompleteLabel.text = "Your slideshow is ready!"
        progressCompleteLabel.frame = self.placeholderLabel.frame
        self.view.addSubview(progressCompleteLabel)
        progressCompleteLabel.isHidden = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
    }
    
    
    @IBAction func backButtonPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func exportShareButton(_ sender: UIButton) {
        
        // removing the paywall for now, just start sharing if they reach this page
        self.shareAction()
        
        /*
         // TODO: check for in-app purchase here
         if let isPurchased = UserDefaults.standard.value(forKey: "isPurchased") as? Bool, isPurchased == true {
         // Product is purchased - share the slideshow
         self.shareAction()
         
         } else {
         /* Product is not purchased */
         let squeezePage = SqueezePageViewController(nibName: "SqueezePageViewController", bundle: .main)
         squeezePage.paywallOrigin = .saveSlideshow
         self.present(squeezePage, animated: true, completion: {
         // check if purchase was made on the squeeze page
         if let isPurchased = UserDefaults.standard.value(forKey: "isPurchased") as? Bool, isPurchased == true {
         self.shareAction()
         }
         })
         }
         */
    }
    
    
    func getMovieData(_ resource: PHAssetResource) {
        
        let movieURL = URL(fileURLWithPath: (NSTemporaryDirectory()).appending("video.mov"))
        removeFileIfExists(fileURL: movieURL)
        
        
        PHAssetResourceManager.default().writeData(for: resource, toFile: movieURL as URL, options: nil) { (error) in
            if error != nil{
                print("Could not write video file")
            } else {
                self.gifURL = movieURL
                self.shareAction()
            }
        }
    }
    
    
    func shareAction() {
        if gifURL != nil {
            let activityVC = UIActivityViewController(activityItems: [gifURL!], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            activityVC.completionWithItemsHandler = { (activityType, completed:Bool, returnedItems:[Any]?, error: Error?) in
                if completed {
                    self.checkNumberOfShares()
                }
            }
            self.present(activityVC, animated: true, completion: nil)
        } else {
            showGenericAlert(popBack: true)
        }
    }
    
    func showGenericAlert(popBack: Bool) {
        if popBack {
            self.navigationController?.popViewController(animated: true)
        }
//        let titleText = "Oops!"
//        var message = "Something went wrong. Please try again."
//        if popBack {
//            message = "An unexpected issue occurred. Please try creating your slideshow again."
//        }
//        let alert = UIAlertController(title: titleText, message: message, preferredStyle: .alert)
//        let okAction = UIAlertAction(title: "OK", style: .default, handler: {_ in
//            if popBack {
//                self.navigationController?.popViewController(animated: true)
//            }
//        })
//        alert.addAction(okAction)
//        self.present(alert, animated: true, completion: nil)
    }
    
    func removeFileIfExists(fileURL : URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            }
            catch {
                print("Could not delete exist file so cannot write to it")
            }
        }
    }
    
    func checkNumberOfShares() {
        var numberOfShares = UserDefaults.standard.float(forKey: "numberOfShares")
        numberOfShares += 1
        if numberOfShares == 2 {
            // increment number of shares
            DispatchQueue.main.async {
                UserDefaults.standard.set(numberOfShares, forKey: "numberOfShares")
                //NOTE: - Removed alert part so it wouldn't ask for review of anything
                let alert = UIAlertController(title: "Are you enjoying Flipagram?", message: "", preferredStyle: .alert)
                let yesAction = UIAlertAction(title: "Yes", style: .default, handler: {_ in
                    // if the user clicks "Yes", show rate the app
                    self.rateTheApp()
                })
                let noAction = UIAlertAction(title: "No", style: .cancel, handler: {_ in
                    let svc = SFSafariViewController(url: URL(string:"http://flipagram.site")!)
                    self.present(svc, animated: true, completion: nil)
                })
                alert.addAction(yesAction)
                alert.addAction(noAction)
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            // increment number of shares
            UserDefaults.standard.set(numberOfShares, forKey: "numberOfShares")
        }
    }
    
    func rateTheApp() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        }
    }
    
    /// Public method to handle the click in the generateSingleAudioMultipleImageButton
    /// Generates a multiple type video from multiple images and single audio
    /// - Parameter sender: a sender of type UIButton
//    func generateMultipleImageSingleAudioVideo() {
//
//        var audioArray = [URL]()
//        for _ in self.finalImageArray {
//            // add the silent 2 and a half second audio clip
//            if let tempAudio = Bundle.main.url(forResource: "2AndAHalfSeconds", withExtension: ".mp3") {
//                audioArray.append(tempAudio)
//            }
//        }
//        VideoGenerator.current.fileName = "MovieURLFilename"
//        VideoGenerator.current.shouldOptimiseImageForVideo = true
//        //VideoGenerator.current.videoDurationInSeconds = 15
//        VideoGenerator.current.videoDurationInSeconds = Double(self.finalImageArray.count * 2)
//        VideoGenerator.current.videoImageWidthForMultipleVideoGeneration = 2000
//
//        VideoGenerator.current.generate(withImages: self.finalImageArray, andAudios: audioArray, andType: .singleAudioMultipleImage, { (progress) in
//            print(progress)
//        }, success: { (url) in
//            //LoadingView.unlockView()
//            DispatchQueue.main.async {
//                self.progressMeter?.frame = (self.progressMeterContainer?.frame)!
//                self.activityIndicator.stopAnimating()
//                self.activityIndicator.removeFromSuperview()
//                self.gifURL = url
//                self.perform(#selector(self.showFinished), with: nil, afterDelay: 0.5)
//            }
//
//            print(url)
//            //self.createAlertView(message: self.FnishedMultipleVideoGeneration)
//        }, failure: { (error) in
//            //LoadingView.unlockView()
//            print(error)
//            //self.createAlertView(message: error.localizedDescription)
//        })
//    }
    
    @objc
    func showFinished() {
        
        self.exportShareButton.isEnabled = true

        progressMeter?.isHidden = true
        progressMeterContainer?.isHidden = true
        progressCompleteLabel.isHidden = false
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: avPlayer?.currentItem)
        
        
        let avAsset = AVAsset(url: gifURL!)
        let playerItem = AVPlayerItem(asset: avAsset)
        avPlayer = AVPlayer(playerItem: playerItem)
        
        let avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = CGRect(x: 0, y: 0, width: self.placeholderView.frame.size.width
            , height: self.placeholderView.frame.size.height)
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.placeholderView.layer.insertSublayer(avPlayerLayer, at: 0)
        self.playVideo()
        
        //avPlayer = AVPlayer(url: gifURL!)
        let avPlayerController = AVPlayerViewController()
        avPlayerController.player = nil
        avPlayerController.player = avPlayer
        avPlayerController.view.frame = self.placeholderView.frame
        //  hide show control
        avPlayerController.showsPlaybackControls = false
        
        avPlayerController.view.clipsToBounds = true
        avPlayerController.view.layer.cornerRadius = 3.0
        //        avPlayerController.videoGravity = AVLayerVideoGravity.resizeAspectFill.rawValue
        
        // play video
        DispatchQueue.main.async {
            avPlayerController.player?.play()
            self.playVideo()
            self.view.addSubview(avPlayerController.view)
            self.view.sendSubviewToBack(avPlayerController.view)
        }
        
        let tapToPlay: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(playVideo))
        tapToPlay.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapToPlay)
        
    }
    
    @objc func playVideo() {
        avPlayer.play()
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
    
//    func createImageArray() {
//
//        let options = PHImageRequestOptions()
//        options.isNetworkAccessAllowed = true
//        options.deliveryMode = .highQualityFormat
//        options.resizeMode = .exact
//        options.isSynchronous = true
//
//        let targetSize = CGSize(width: 1200, height: 1600)
//
//        let semaphore = DispatchSemaphore(value: 0)
//
//        let manager = PHImageManager.default()
//        for i in 0..<self.imageAssets.count {
//            let asset = self.imageAssets[i]
//            DispatchQueue.global(qos: .background).async {
//                manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { (image: UIImage?, info: [AnyHashable : Any]?) in
//                    // assign the asset to the button
//                    if image == nil || info == nil {
//                        semaphore.signal()
//                        return
//                    }
//                    self.finalImageArray.append(image!)
//
//                    semaphore.signal()
//
//                    if self.finalImageArray.count == self.imageAssets.count {
//                        // once the image array has been created, generate the slideshow video
//                        self.generateMultipleImageSingleAudioVideo2()
//
//                    }
//                })
//            }
//            // tell the semaphore to wait until we retrieve the image
//            semaphore.wait()
//
//        }
//
//
//    }
    
    
    
    
    
    func generateMultipleImageSingleAudioVideo2() {
        
        var finalVideoURLArray = [URL]()
        
        let imageCount = 10
        var numOfLoops = Int(self.finalImageArray.count / imageCount)
        
        let myRemainder = Int(self.finalImageArray.count) % imageCount
        if myRemainder != 0 {
            numOfLoops += 1
        }
        
        autoreleasepool {
            // semaphore to wait for videos to be generated so that we are not generating multiple videos at the same time (not enough computing power to handle that - it will crash)
            let semaphore = DispatchSemaphore(value: 0)
            
            for i in 0..<numOfLoops {
                var newImageCount = imageCount
                if i+1 == numOfLoops && myRemainder != 0 {
                    newImageCount = myRemainder
                }
                
                var tempAudioArray = [URL]()
                var tempImgArray = [UIImage]()
                let imgIndex = Int(i * newImageCount)
                for n in 0..<newImageCount {
                    tempImgArray.append(self.finalImageArray[imgIndex+n])
                    // add the silent 2 and a half second audio clip
                    if let tempAudio = Bundle.main.url(forResource: "2AndAHalfSeconds", withExtension: ".mp3") {
                        tempAudioArray.append(tempAudio)
                    }
                }
                
                VideoGenerator.current.fileName = "MovieURLFilename\(i)"
                VideoGenerator.current.shouldOptimiseImageForVideo = true
                VideoGenerator.current.videoDurationInSeconds = Double(tempImgArray.count * 2)
                VideoGenerator.current.videoImageWidthForMultipleVideoGeneration = 1200
                
                VideoGenerator.current.generate(withImages: tempImgArray, andAudios: tempAudioArray, andType: .singleAudioMultipleImage, { (progress) in
                    print(progress)
                }, success: { (url) in
                    // signal semaphore to continue the loop
                    
                    self.gifURL = url
                    finalVideoURLArray.append(url)
                    semaphore.signal()
                    
                    DispatchQueue.main.async {
                        let estWidth = self.view.frame.size.width - 100
                        var myHeight = CGFloat(30)
                        if let hgt = self.progressMeter?.frame.size.height {
                            myHeight = hgt
                        }
                        let myWidth = (estWidth / CGFloat(numOfLoops + 1)) * CGFloat(i + 1)
                        self.progressMeter?.frame = CGRect(x: 50, y: 60, width: myWidth, height: myHeight)
                    }
                    
                    print(url)
                }, failure: { (error) in
                    //LoadingView.unlockView()
                    print(error)
                    semaphore.signal()
                    self.navigationController?.popViewController(animated: true)

                })
                // semaphore to wait for video to be generated
                semaphore.wait()
                
            }
        }
        
        
        if numOfLoops < 2 {
            DispatchQueue.main.async {
                self.progressMeter?.frame = (self.progressMeterContainer?.frame)!
                self.activityIndicator.stopAnimating()
                self.activityIndicator.removeFromSuperview()
                self.perform(#selector(self.showFinished), with: nil, afterDelay: 0.5)
            }
            return
        }
        
        print("done")
        // reverse the array it was saved backwards
        finalVideoURLArray = finalVideoURLArray.reversed()
        
        autoreleasepool {
            VideoGenerator.mergeMovies(videoURLs: finalVideoURLArray, andFileName: "MergedMovieFileName", success: { (videoURL) in
                //            LoadingView.unlockView()
                //            self.createAlertView(message: self.FinishedMergingVideos)
                print(videoURL)
                DispatchQueue.main.async {
                    self.progressMeter?.frame = (self.progressMeterContainer?.frame)!
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.removeFromSuperview()
                    self.gifURL = videoURL
                    self.perform(#selector(self.showFinished), with: nil, afterDelay: 0.5)
                }
                
            }) { (error) in
                //            LoadingView.unlockView()
                print(error)
                self.navigationController?.popViewController(animated: true)
                //            self.createAlertView(message: error.localizedDescription)
            }
        }
        
    }
    
    
    
    
    
}
