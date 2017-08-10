//
//  ScrollableImageViewController.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 7/25/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//

import UIKit


final class ScrollableImageViewController: UIViewController, UIScrollViewDelegate, SelfieImageDelegate {

    fileprivate var mustInitializeZoom = true
    
    var selfieImage:UIImage? {
        didSet {
            imageView.image = selfieImage
            scrollView?.contentSize = imageView.frame.size
            imageView.sizeToFit()
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.contentSize = imageView.frame.size
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.03
            scrollView.maximumZoomScale = 1.0
        }
    }
    
    fileprivate var imageView = UIImageView()
    
    func clearSelfieImage() {
        selfieImage = nil
    }
    
    func zoomToFit() {
        if mustInitializeZoom {
            if let iViewImage = imageView.image {
                let iw = iViewImage.size.width
                let vw = scrollView!.superview!.frame.width
                scrollView.zoomScale = vw / iw
            } else {
                scrollView.zoomScale = 1.0
            }
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        mustInitializeZoom = false
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftItemsSupplementBackButton=true
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        scrollView.addSubview(imageView)
    }
    
    override func viewDidLayoutSubviews() {
        zoomToFit()
    }
}
