//
//  ViewController.swift
//  StackEm
//
//  Created by David Charlec on 2017-08-18.
//  Copyright © 2017 David Charlec. All rights reserved.
//

import UIKit
import Photos

enum StackEmButton {
    case original
    case render
    case undefined
}

class ViewController: UIViewController, ImagePickerSetsViewControllerDelegate {
    
    var lastButton: UIButton?
    var activeButton = StackEmButton.undefined
    var originalAsset: PHAsset?
    var renderedAsset: PHAsset?
    var renderedData: Data?
    
    var originalPicker: UINavigationController?
    var renderPicker: UINavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func topButtonAction(_ sender: UIButton) {
        activeButton = .original
        lastButton = sender
        pickPhoto()
    }
    
    @IBAction func bottomButtonAction(_ sender: UIButton) {
        activeButton = .render
        lastButton = sender
        pickPhoto()
    }
    
    @IBAction func mergeButtonAction(_ sender: UIButton) {
        if let asset = self.originalAsset, let data = self.renderedData {
            
            let inputOptions = PHContentEditingInputRequestOptions()
            inputOptions.isNetworkAccessAllowed = true
            inputOptions.canHandleAdjustmentData = { (data: PHAdjustmentData) -> (Bool) in
                return true
            }
            
            asset.requestContentEditingInput(with: inputOptions, completionHandler: { (input, info) in
                if let input = input {
                    let output = PHContentEditingOutput(contentEditingInput: input)
                    do {
                        try data.write(to: output.renderedContentURL, options: .atomic)
                    } catch {
                        return
                    }
                    let adjustments = ["flat": "marjo"]
                    output.adjustmentData = PHAdjustmentData(formatIdentifier: "com.davidcharlec.stackem", formatVersion: "1.0", data: NSKeyedArchiver.archivedData(withRootObject: adjustments))
                    
                    PHPhotoLibrary.shared().performChanges({
                        let changeRequest = PHAssetChangeRequest(for: asset)
                        

                        changeRequest.contentEditingOutput = output
                    }, completionHandler: { (success, error) in
                        self.deleteRenderedAsset()
                    })
                }
            })
        }
    }


    
    func pickPhoto() {
        var picker: UINavigationController?
        
        if self.activeButton == .original {
            if self.originalPicker == nil {
                self.originalPicker = generatePickerNavigationController()
            }
            picker = self.originalPicker
        } else if self.activeButton == .render {
            if self.renderPicker == nil {
                self.renderPicker = generatePickerNavigationController()
            }
            picker = self.renderPicker
        }
        
        if let picker = picker {
            present(picker, animated: true) {
                //
            }
        }
    }

    func generatePickerNavigationController() -> UINavigationController {
        let picker = ImagePickerSetsViewController()
        picker.delegate = self
        return UINavigationController(rootViewController: picker)
    }
    
    func imagePickerSetsViewController(_ imagePickerSetsViewController: ImagePickerSetsViewController!, userDidSelect group: PHAssetCollection!) {
        //
    }
    
    func imagePickerSetsViewController(_ imagePickerSetsViewController: ImagePickerSetsViewController!, userDidSelect asset: PHAsset!) {
        
        let options = PHImageRequestOptions()
        options.resizeMode = .none
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .original
        options.isSynchronous = false

        if activeButton == .original {
            self.originalAsset = asset
        } else if activeButton == .render {
            self.renderedAsset = asset
            PHCachingImageManager.default().requestImageData(for: asset, options: options) { (data, uti, orientation, info) in
                self.renderedData = data
            }
        }
        
        PHCachingImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 600, height: 600), contentMode: .aspectFit, options: options) { (image, info) in
            self.lastButton!.setBackgroundImage(image, for: .normal)
        }
        
        dismiss(animated: true) {
            //
        }
    }
    
    func deleteRenderedAsset() {
        let assetsToDelete = NSArray(object: self.renderedAsset!)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete)
        }, completionHandler: {success, error in
            print(success ? "Success" : "SAD" )
        })
    }
    
    func userDidDismiss(_ imagePickerSetsViewController: ImagePickerSetsViewController!) {
        dismiss(animated: true) {
            //
        }
    }}

