//
//  ColorPaleteControl.swift
//  FlexColorPicker
//
//  Created by Rastislav Mirek on 27/5/18.
//  
//	MIT License
//  Copyright (c) 2018 Rastislav Mirek
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit

let minimumDistanceForInBoundsTouchFromValidPoint: CGFloat = 44
let defaultSelectedColor = UIColor.white.hsbColor

@IBDesignable
open class ColorPaletteControl: ColorControlWithThumbView {
    /// The picture with hue and saturation color options.
    public let foregroundImageView = UIImageView()
    /// Black image in the background used to apply brightnes chnage by blending it with colorMapImageView.
    public let backgroundImageView = UIImageView()
    
    open var paletteDelegate: ColorPaletteDelegate = RadialHSBPaletteDelegate() {
        didSet {
            updatePaleteImagesAndThumb(isInteractive: false)
        }
    }
    open override var bounds: CGRect {
        didSet {
            updatePaleteImagesAndThumb(isInteractive: false)
        }
    }

    open override var contentMode: UIViewContentMode {
        didSet {
            updateContentMode()
            updateThumbPosition(position: paletteDelegate.positionAndAlpha(for: selectedHSBColor).position)
        }
    }

    open override func commonInit() {
        super.commonInit()
        contentView.addAutolayoutFillingSubview(backgroundImageView)
        backgroundImageView.addAutolayoutFillingSubview(foregroundImageView)
        updateContentMode()
        contentView.addSubview(thumbView)
        updatePaleteImagesAndThumb(isInteractive: false)
    }

    open override func setSelectedHSBColor(_ hsbColor: HSBColor, isInteractive interactive: Bool) {
        let hasChanged = selectedHSBColor != hsbColor
        super.setSelectedHSBColor(hsbColor, isInteractive: interactive)
        if hasChanged {
            thumbView.setColor(hsbColor.toUIColor(), animateBorderColor: interactive)
            let (position, foregroundAlpha) = paletteDelegate.positionAndAlpha(for: hsbColor)
            updateThumbPosition(position: position)
            foregroundImageView.alpha = foregroundAlpha
        }
    }

    open func updatePaleteImagesAndThumb(isInteractive interactive: Bool) {
        layoutIfNeeded() //force subviews layout to update their bounds - bounds of subviews are not automatically updated
        paletteDelegate.size = foregroundImageView.bounds.size //cannot use self.bounds as that is extended compared to foregroundImageView.bounds when AdjustedHitBoxColorControl.hitBoxInsets are non-zero
        foregroundImageView.image = paletteDelegate.foregroundImage()
        backgroundImageView.image = paletteDelegate.backgroundImage()
        assert(foregroundImageView.image!.size.width <= paletteDelegate.size.width && foregroundImageView.image!.size.height <= paletteDelegate.size.height, "Size of rendered image must be smaller or equal specified palette size")
        assert(backgroundImageView.image == nil || foregroundImageView.image?.size == backgroundImageView.image?.size, "foreground and background images rendered must have same size")
        updateContentMode()
        updateThumbPosition(position: paletteDelegate.positionAndAlpha(for: selectedHSBColor).position)
        thumbView.setColor(selectedColor, animateBorderColor: interactive)
    }

    open func imageCoordinates(point: CGPoint, fromCoordinateSpace coordinateSpace: UICoordinateSpace) -> CGPoint {
        return foregroundImageView.convertToImageSpace(point: foregroundImageView.convert(point, from: coordinateSpace))
    }

    open func imageCoordinates(point: CGPoint, toCoordinateSpace coordinateSpace: UICoordinateSpace) -> CGPoint {
        return foregroundImageView.convert(foregroundImageView.convertFromImageSpace(point: point), to: coordinateSpace)
    }

    /// Not ready to be called directly but you may override
    open override func updateSelectedColor(at point: CGPoint) {
        let pointInside = paletteDelegate.closestValidPoint(to: imageCoordinates(point: point, fromCoordinateSpace: contentView))
        setSelectedHSBColor(paletteDelegate.modifiedColor(from: selectedHSBColor, with: pointInside), isInteractive: true)
        updateThumbPosition(position: pointInside)
        sendActions(for: .valueChanged)
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let maxTouchDistance = max(hitBoxInsets.bottom, hitBoxInsets.top, hitBoxInsets.left, hitBoxInsets.right, minimumDistanceForInBoundsTouchFromValidPoint)
        if imageCoordinates(point: paletteDelegate.closestValidPoint(to: imageCoordinates(point: point, fromCoordinateSpace: self)), toCoordinateSpace: self).distance(to: point) > maxTouchDistance {
            return nil
        }
        return super.hitTest(point, with: event)
    }

    private func updateThumbPosition(position: CGPoint) {
        thumbView.frame = CGRect(center: imageCoordinates(point: position, toCoordinateSpace: contentView), size: thumbView.intrinsicContentSize)
    }

    private func updateContentMode() {
        let contentMode = paletteDelegate.supportedContentMode(for: self.contentMode)
        backgroundImageView.contentMode = contentMode
        foregroundImageView.contentMode = contentMode
    }
}