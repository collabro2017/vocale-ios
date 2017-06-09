//
//  UIImageExtension.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/12/09.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class UIImageExtension: UIImage {

}

extension UIImage {

    enum AssetIdentifier: String {
        case VocaleClearWhite = "VocaleClearWhite"
        case VocaleGradient = "VocaleGradient"
        case VocaleClearBlack = "VocaleClearBlack"
        case redSquare = "redSquare"
        case voiceNoteUploadCheck = "voiceNoteUploadCheck"
        case voiceNoteUploadArrow = "voiceNoteUploadArrow"
        case bookmarkButton = "bookmarkButton"
        case bookmarkedButton = "bookmarkedButton"
        case returnButton = "returnButton"
    }

    convenience init!(assetIdentifier: AssetIdentifier) {
        self.init(named: assetIdentifier.rawValue)
    }

    /**
     A blurred version of this image.

     - returns: Blurred UIImage.
     */
    func blurredImage() -> UIImage {

        var weight: [CGFloat] = [0.1870270270, 0.2345945946, 0.1816216216, 0.0940540541, 0.0762162162, 0.0940540541, 0.16162162162, 0.1962162162, 0.2040540541, 0.0662162162]
        UIGraphicsBeginImageContextWithOptions(self.size, Bool(false), self.scale)
        self.drawInRect(CGRectMake(0, 0, self.size.width, self.size.height), blendMode: .Normal, alpha: weight[0])

        var blurCount  = Int(7)

        if(blurCount > 9) {
            blurCount = 9
        }

        for index in 1...blurCount {
            self.drawInRect(CGRectMake(CGFloat(index), 0, self.size.width, self.size.height), blendMode: .Normal, alpha: weight[index])
            self.drawInRect(CGRectMake(CGFloat(-index), 0, self.size.width, self.size.height), blendMode: .Normal, alpha: weight[index])
        }
        let horizBlurredImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        UIGraphicsBeginImageContextWithOptions(self.size, Bool(false), self.scale)
        horizBlurredImage.drawInRect(CGRectMake(0, 0, self.size.width, self.size.height), blendMode:.Normal, alpha:weight[0] )
        for index in 1...blurCount {
            horizBlurredImage.drawInRect(CGRectMake(0, CGFloat(index), self.size.width, self.size.height), blendMode:.Normal, alpha:weight[index])
            horizBlurredImage.drawInRect(CGRectMake(0, CGFloat(-index), self.size.width, self.size.height), blendMode:.Normal, alpha:weight[index])
        }
        let blurredImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()
        return blurredImage
    }

    /**
     The NSData of the image concerned, compressed by factor 1.

     - returns: Compressed NSData (JPEG formatted) of this UIImage.
     */
    func compressedImageData() -> NSData? {
        var actualHeight: CGFloat = self.size.height
        var actualWidth: CGFloat = self.size.width
        let maxHeight: CGFloat = 1136.0
        let maxWidth: CGFloat = 640.0
        var imgRatio: CGFloat = actualWidth/actualHeight
        let maxRatio: CGFloat = maxWidth/maxHeight
        var compressionQuality: CGFloat = 1.0

        if (actualHeight > maxHeight || actualWidth > maxWidth) {
            if(imgRatio < maxRatio) {
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            } else if(imgRatio > maxRatio) {
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            } else {
                actualHeight = maxHeight
                actualWidth = maxWidth
                compressionQuality = 1
            }
        }

        let rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        self.drawInRect(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        let imageData = UIImageJPEGRepresentation(img, compressionQuality)
        UIGraphicsEndImageContext()

        return imageData
    }

    /**
     Image masked to square.

     - returns: Square version of this UIImage.
     */
    func squareImage() -> UIImage {
        let contextImage: UIImage = UIImage(CGImage: self.CGImage!)
        let contextSize: CGSize = contextImage.size

        let posX: CGFloat
        let posY: CGFloat
        let width: CGFloat
        let height: CGFloat

        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            width = contextSize.height
            height = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            width = contextSize.width
            height = contextSize.width
        }

        let rect: CGRect = CGRectMake(posX, posY, width, height)
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage!, rect)!
        let image: UIImage = UIImage(CGImage: imageRef, scale: self.scale, orientation: self.imageOrientation)

        return image
    }

    /**
     Image masked to an ellipse, fitting within the UIImage.

     - returns: Circular version of this UIImage.
     */
    func circularImage() -> UIImage {
        let newImage = self.copy() as! UIImage
        let cornerRadius = self.size.height/2
        UIGraphicsBeginImageContextWithOptions(self.size, false, 1.0)
        let bounds = CGRect(origin: CGPoint.zero, size: self.size)
        UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).addClip()
        newImage.drawInRect(bounds)
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return finalImage!
    }

    /**
     Image masked to an ellipse, fitting within the UIImage - rounded with a white border.

     - returns: Circular, stroked version of this UIImage.
     */
    func circularImageWithBorder() -> UIImage {
        let newImage = self.copy() as! UIImage
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)

        let path = UIBezierPath(roundedRect: CGRectInset(CGRectMake(0, 0, self.size.width, self.size.height), 6, 6), cornerRadius: self.size.height/2)
        let context = UIGraphicsGetCurrentContext()!

        CGContextSaveGState(context)
        path.addClip()
        newImage.drawInRect(CGRectMake(0, 0, self.size.width, self.size.height))
        CGContextRestoreGState(context)
        UIColor.vocaleFilterTextColor().setStroke()
        path.lineWidth = 6
        path.stroke()

        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return roundedImage
    }
    
    func circularImageWithBorderDark() -> UIImage {
        let newImage = self.copy() as! UIImage
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        
        let path = UIBezierPath(roundedRect: CGRectInset(CGRectMake(0, 0, self.size.width, self.size.height), 6, 6), cornerRadius: self.size.height/2)
        let context = UIGraphicsGetCurrentContext()!
        
        CGContextSaveGState(context)
        path.addClip()
        newImage.drawInRect(CGRectMake(0, 0, self.size.width, self.size.height))
        CGContextRestoreGState(context)
        UIColor.lightGrayColor().setStroke()
        path.lineWidth = 6
        path.stroke()
        
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return roundedImage
    }
}
