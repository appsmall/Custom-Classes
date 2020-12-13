//
//  RCPhotos.swift
//  RCPhotos
//
//  Created by Rahul Chopra on 10/12/20.
//  Copyright © 2020 com.appsmall.rcphotos. All rights reserved.
//

import Foundation
import UIKit
import Photos

protocol RCPhotosDelegate: class {
    func getAssets()
}

class RCPhotos {
    
    static let shared = RCPhotos()
    private init() { }
    
    var qualityType: PHImageRequestOptionsDeliveryMode = .highQualityFormat
    var images = [UIImage]()
    var imageSize: CGSize = CGSize(width: 1024, height: 1024)
    var assets = [PHAsset]()
    var recentPhotoAssets = [PHAsset]()
    weak var delegate: RCPhotosDelegate?
    
    func configure() {
        
    }
    
    func requestAuthorization(completion: ((_ isAuthorized: Bool) -> ())? = nil) {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                print("Authorized")
                
            case .denied:
                print("Denied")
                
            case .notDetermined:
                print("Not determined")
                
            case .restricted:
                print("Restricted")
                
            @unknown default:
                print("Unknown")
            }
        }
    }
    
    
    // SAVE IMAGES IN THE PHOTO LIBRARY
    func saveImageInPhotoLibrary(image: UIImage, completion: ((Bool) -> ())? = nil) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { (status, error) in
            if let err = error {
                print(err)
                if completion != nil {
                    completion!(false)
                }
                return
            }
            if completion != nil {
                completion!(status)
            }
        }
    }
    
    func getAssetsFromLibrary(type: PHAssetMediaType = .image, thumbnailSize: CGSize, completion: @escaping((Bool) -> ())) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let results: PHFetchResult = PHAsset.fetchAssets(with: type, options: fetchOptions)
        if results.count > 0 {
            self.assets.removeAll()
            for i in 0..<results.count {
                self.assets.append(results.object(at: i))
            }
            completion(true)
        } else {
            print("No photos in the library")
            completion(false)
        }
    }
    
    
    func requestImage(asset: PHAsset, completion: @escaping((UIImage?) -> ())) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = qualityType
        
        let manager = PHImageManager()
        manager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: requestOptions) { (image, _) in
            if let image = image {
                completion(image)
            } else {
                completion(nil)
            }
        }
    }
    
    func fetchRecentPhotos(completion: @escaping((Bool) -> ())) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.fetchLimit = 3

        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        if fetchResult.count > 0 {
            self.recentPhotoAssets.removeAll()
            for i in 0..<fetchResult.count {
                self.recentPhotoAssets.append(fetchResult.object(at: i))
            }
            completion(true)
        } else {
            completion(false)
        }
    }
}
