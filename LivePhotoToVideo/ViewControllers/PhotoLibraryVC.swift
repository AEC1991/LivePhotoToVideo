//
//  PhotoLibraryVC.swift
//  filterra
//
//  Created by Murphy Brantley on 8/25/18.
//  Copyright © 2018 Murphy Brantley. All rights reserved.
//

import Foundation

import Photos
import PhotosUI
import MessageUI
import StoreKit

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class CollectionViewDataModel {
    var asset: PHAsset?
    var isSelected = false
}

class PhotoLibraryVC: UICollectionViewController, MFMessageComposeViewControllerDelegate {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // Photo Library Properties
    var fetchResult: PHFetchResult<PHAsset>!
    var assetCollection: PHAssetCollection!
    var noPhotosLabel: UILabel?
    
    var collectionViewData = [CollectionViewDataModel]()
    
    var downloadView: UIView?
    var downloadLabel: UILabel?
    var downloadButton: UIButton?
    
    fileprivate lazy var imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero
    
    var selectedImageAssets = [PHAsset]()
    var selectedImageArray = [UIImage]()
    
    let numberOfCellsPerRow: CGFloat = 3

    // MARK: UIViewController / Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        getPhotoAccess()

        createNoPhotosFoundLabel()
        createDownloadView()
        PHPhotoLibrary.shared().register(self)
        
        // load all photos from the library
        if fetchResult == nil {
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchResult = PHAsset.fetchAssets(with: .image, options: allPhotosOptions)
            if fetchResult?.count == 0 {
                self.noPhotosLabel?.isHidden = false
            } else {
                self.noPhotosLabel?.isHidden = true
            }
        }
        
        // populate data for the collection view
        createCollectionViewData()
        
        self.collectionView?.frame = CGRect(x: 0, y: 100, width: self.view.frame.size.width, height: self.view.frame.size.height - 100)
        
        // add the header view to the top of the collection view
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 100))
        headerView.backgroundColor = .black
        
        let headerIcon = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        headerIcon.center = CGPoint(x: headerView.center.x, y: headerView.center.y + 10)
        headerIcon.setBackgroundImage(UIImage(named:"iconImage"), for: .normal)
        headerIcon.addTarget(self, action: #selector(shareButtonPressed), for: .touchUpInside)
        
        let backIcon = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        backIcon.center = CGPoint(x: headerView.center.x - headerView.center.x + 30, y: headerView.center.y + 10)
        backIcon.setBackgroundImage(UIImage(named:"closeIcon"), for: .normal)
        backIcon.addTarget(self, action: #selector(loadCameraView), for: .touchUpInside)
        
        let topIcon = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        topIcon.center = CGPoint(x: headerView.center.x + headerView.center.x - 30, y: headerView.center.y + 10)
        topIcon.setBackgroundImage(UIImage(named:"SlideshowView"), for: .normal)
        topIcon.addTarget(self, action: #selector(loadVideoOfTheWeekView), for: .touchUpInside)
        
        headerView.addSubview(headerIcon)
        headerView.addSubview(backIcon)
        headerView.addSubview(topIcon)
        
        self.view.addSubview(headerView)
        
        checkInAppPurchases()
    }

    
    func getPhotoAccess() {
        //Photos
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos != .authorized {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self.noPhotosLabel?.isHidden = true
                    }
                    self.resetCachedAssets()
                } else {
                    DispatchQueue.main.async {
                        self.noPhotosLabel?.text = "No access to photos.\n\n We need access to your photos so you can create slideshows.\n\nGrant access to photos in Settings."
                        DispatchQueue.main.async {
                            self.noPhotosLabel?.isHidden = false                            
                        }
                        self.showSettingsAlert()
                    }
                }
            })
        } else {
            noPhotosLabel?.isHidden = true
            self.resetCachedAssets()
        }
    }
    
    func showSettingsAlert() {
        let alert = UIAlertController(title: "No Photo Access", message: "We need access to your photos so you can create slideshows.\n\nGrant access to photos in Settings.", preferredStyle: .alert)
        let notNowAction = UIAlertAction(title: "Not Now", style: .cancel, handler: nil)
        let settingAction = UIAlertAction(title: "Settings", style: .default, handler: {_ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        })
        alert.addAction(notNowAction)
        alert.addAction(settingAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func checkInAppPurchases() {
        // TODO: check in app purchases
        if let isPurchased = UserDefaults.standard.value(forKey: "isPurchased") as? Bool, isPurchased == true {
            // Product is purchased
            // do nothing
        } else {
            /* Product is not purchased */
            //FIXME: - Bradley did this, uncommented next four lines.
//            let squeezePage = SqueezePageViewController(nibName: "SqueezePageViewController", bundle: .main)
//            squeezePage.paywallOrigin = .firstLoad
//            self.present(squeezePage, animated: true, completion: nil)
        }

    }
    
    func createCollectionViewData() {
        collectionViewData.removeAll()
        for i in 0..<fetchResult.count {
            
            let asset = fetchResult[i]
            let dataModel = CollectionViewDataModel()
            dataModel.asset = asset
            dataModel.isSelected = false
            collectionViewData.append(dataModel)
        }
        collectionView?.reloadData()
    }
    
    func createDownloadView() {
        downloadView = UIView(frame: CGRect(x: 40, y: self.view.frame.size.height - 80, width: self.view.frame.size.width - 80, height: 50))
        downloadView?.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.7)
        downloadView?.clipsToBounds = true
        downloadView?.layer.borderColor = UIColor.white.cgColor
        downloadView?.layer.borderWidth = 1.0
        downloadView?.layer.borderColor = UIColor.white.cgColor
        downloadView?.layer.cornerRadius = (downloadView?.frame.size.height)! / 2

        if selectedImageAssets.isEmpty {
            self.downloadView?.alpha = 0.0
        } else {
            self.downloadView?.alpha = 1.0
        }
        
        downloadLabel = UILabel(frame: CGRect(x: 0, y: 0, width: (downloadView?.frame.size.width)!, height: (downloadView?.frame.size.height)!))
        downloadLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        downloadLabel?.textColor = UIColor.white
        downloadLabel?.text = "\(selectedImageAssets.count) photos selected"
        downloadLabel?.textAlignment = .center
        downloadLabel?.sizeToFit()
        downloadLabel?.center = CGPoint(x: (downloadView?.frame.size.width)!/2, y: (downloadView?.frame.size.height)!/2)
        downloadView?.addSubview(downloadLabel!)
        
        let downArrow: UIImageView = UIImageView(frame: CGRect(x: (downloadLabel?.frame.origin.x)! - 28, y: 5, width: 20, height: 20))
        downArrow.center = CGPoint(x: downArrow.center.x, y: (downloadLabel?.center.y)!)
        downArrow.contentMode = .scaleAspectFit
        downArrow.image = UIImage(named: "downArrow")
        downloadView?.addSubview(downArrow)
        

        downloadButton = UIButton(frame: CGRect(x: 0, y: 0, width: (downloadView?.frame.size.width)!, height: (downloadView?.frame.size.height)!))
        downloadButton?.clipsToBounds = true
        downloadButton?.addTarget(self, action: #selector(createSlideshow), for: .touchUpInside)
        downloadView?.addSubview(downloadButton!)
        
        self.view.addSubview(downloadView!)

    }
    
    @objc
    func createSlideshow() {
        //NOTE: - Bradley deleted what was previously here so that you wouldn't be asked to pay under any circumstances
        
        // delete any videos that were stored previously
        clearTempFolder()
        
        navigateToSlideshowViewController()
    }
    
    func navigateToSlideshowViewController() {
        // pass the image assets to the next view
        guard let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "SlideshowCreationVC") as? SlideshowCreationVC else {
            return
        }

        photoVC.finalImageArray = self.selectedImageArray
        print("Assets: \(self.selectedImageAssets.count)")
        print("Images: \(self.selectedImageArray.count)")
        
        self.navigationController?.pushViewController(photoVC, animated: true)
    }
    
    func clearTempFolder() {
        let fileManager = FileManager.default
        let tempFolderPath = NSTemporaryDirectory()
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: tempFolderPath + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
    func createNoPhotosFoundLabel() {
        noPhotosLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width - 32, height: 250))
        noPhotosLabel?.numberOfLines = 0
        noPhotosLabel?.textAlignment = .center
        noPhotosLabel?.center = self.view.center
        noPhotosLabel?.textColor = .white
        noPhotosLabel?.font = UIFont.systemFont(ofSize: 17.0)
        noPhotosLabel?.text = "No Photos Found"
        noPhotosLabel?.isHidden = true
        self.view.addSubview(noPhotosLabel!)
        self.view.bringSubviewToFront(noPhotosLabel!)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        getPhotoAccess()
        
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            let horizontalSpacing = flowLayout.scrollDirection == .vertical ? flowLayout.minimumInteritemSpacing : flowLayout.minimumLineSpacing
            let cellWidth = (view.frame.width - max(0, numberOfCellsPerRow - 1)*horizontalSpacing)/numberOfCellsPerRow
            let cellHeight = (cellWidth * 4) / 3
            flowLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            thumbnailSize = flowLayout.itemSize
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    
    // MARK: UICollectionView
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionViewData.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dataModel = collectionViewData[indexPath.row]
        let asset = dataModel.asset
        
        // Dequeue a GridViewCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GridViewCell.self), for: indexPath) as? GridViewCell
            else { fatalError("unexpected cell in collection view") }
        
        cell.imageView.clipsToBounds = true
        cell.imageView.layer.cornerRadius = 8.0
        cell.imageView.layer.borderWidth = 2.0
        
        if dataModel.isSelected {
            cell.imageView.layer.borderColor = UIColor.yellow.cgColor
        } else {
            cell.imageView.layer.borderColor = UIColor.clear.cgColor
        }
        
        // Request an image for the asset from the PHCachingImageManager.
        cell.representedAssetIdentifier = asset?.localIdentifier
        imageManager.requestImage(for: asset!, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            // The cell may have been recycled by the time this handler gets called;
            // set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset?.localIdentifier {
                cell.thumbnailImage = image
            }
        
        })
                
        return cell
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let dataModel = collectionViewData[indexPath.row]
        // switch selection of data model
        dataModel.isSelected = !dataModel.isSelected
        
        // add PHAsset's to selectedImageAssets array based on whether the cell is selected
        if dataModel.isSelected {
            self.selectedImageAssets.append(dataModel.asset!)
            
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isSynchronous = true
            
            let targetSize = CGSize(width: 1200, height: 1600)
            
            let manager = PHImageManager.default()
            DispatchQueue.global(qos: .background).async {
                manager.requestImage(for: dataModel.asset!, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { (image: UIImage?, info: [AnyHashable : Any]?) in
                    if image != nil {
                        self.selectedImageArray.append(image!)
                    }
                }
            )}
                
        } else {
            for i in 0..<self.selectedImageAssets.count {
                if self.selectedImageAssets[i] == dataModel.asset {
                    self.selectedImageAssets.remove(at: i)
                    self.selectedImageArray.remove(at: i)
                    break
                }
            }
        }
        
        
        if !selectedImageAssets.isEmpty {
            UIView.animate(withDuration: 0.25, animations: {
                // do an animation
                // update the selected images label
                self.downloadLabel?.text = "\(self.selectedImageAssets.count) photos selected"
                self.downloadLabel?.sizeToFit()
                self.downloadView?.alpha = 1.0
            })
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                // do an animation
                self.downloadView?.alpha = 0.0
            })
        }
        
        // replace the selected item
        collectionViewData.remove(at: indexPath.row)
        collectionViewData.insert(dataModel, at: indexPath.row)
        self.collectionView?.reloadItems(at: [indexPath])
    }
    
    // MARK: UIScrollView
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    // MARK: Asset Caching
    
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
    // MARK: UI Actions
    
    @objc
    func shareButtonPressed() {

        //FIXME: - Add HTTPS
        let firstActivityText = "OMG! This team is bringing Flipagram back and better than ever and would love our input..have 5 min to fill out a form? You could win a $25 giftcard. http://flipagram.site"
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [firstActivityText], applicationActivities: nil)
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        controller.dismiss(animated: true, completion: nil)
    }
    
    @objc func loadCameraView() {
        self.performSegue(withIdentifier: "cameraView", sender: self)
    }
    
    @objc func loadVideoOfTheWeekView() {
        self.performSegue(withIdentifier: "videoOfWeek", sender: self)
    }
    

}

// MARK: PHPhotoLibraryChangeObserver
extension PhotoLibraryVC: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        
        guard let changes = changeInstance.changeDetails(for: fetchResult)
            else { return }
        
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.async {
            // Hang on to the new fetch result.
            self.fetchResult = changes.fetchResultAfterChanges
            
            // create data for the collection view
            self.createCollectionViewData()

            /*
            if changes.hasIncrementalChanges {
                // If we have incremental diffs, animate them in the collection view.
                guard let collectionView = self.collectionView else { fatalError() }
                
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
                
            } else {
                // Reload the collection view if incremental diffs are not available.
                self.collectionView?.reloadData()
            }
 */
            // only reset cached assets if you have photo library permissions granted
            if PHPhotoLibrary.authorizationStatus() == .authorized {
                self.resetCachedAssets()
            }
        }
    }
}
