//
//  VideoOfTheWeekViewController.swift
//  LivePhotoToVideo
//
//  Created by Bradley GIlmore on 5/1/19.
//  Copyright © 2019 Bradley Gilmore. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit


class VideoOfTheWeekViewController: UIViewController {

    //MARK: - IBOutlets
    
    @IBOutlet weak var videoView: UIView!
    
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let filepath: String = Bundle.main.path(forResource: "videoOfTheWeek", ofType: "MP4")!
        let fileURL = URL.init(fileURLWithPath: filepath)
        
        let player = AVPlayer(url: fileURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.videoView.bounds
        self.videoView.layer.addSublayer(playerLayer)
        player.play()
    }
    
    //MARK: - IBActions

    @IBAction func exitButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
