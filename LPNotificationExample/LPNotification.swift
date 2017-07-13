//
//  LPNotification.swift
//  LPNotificationExample
//
//  Created by Dinh Van Tai on 2017/07/13.
//  Copyright © 2017 Dinh Van Tai. All rights reserved.
//

import UIKit
import AudioToolbox

protocol LPNotificationDelegate: class {
    func pushTapHandler()
    func pushCompleteHandler()
}

class LPNotification: UIWindow {
    
    // MARK: - Properties
    
    struct CONST {
        static let PADDING: CGFloat = 8.0
        static let DEFAULT_HEIGHT: CGFloat = 120.0
        static let HIDDEN_POS: CGFloat = -300
        static let SLIDE_DOWN_DURATION: TimeInterval = 1.0
        static let SLIDE_UP_DURATION: TimeInterval = 0.3
        static let SHOW_DURATION: Double = 5.0
        static let PUSH_SOUND_ID: SystemSoundID = 1007
    }
    
    @IBOutlet weak fileprivate var vHeader: UIView!
    @IBOutlet weak fileprivate var imgIcon: UIImageView!
    @IBOutlet weak fileprivate var lbBody: UILabel!
    @IBOutlet weak fileprivate var lbTitle: UILabel!
    
    fileprivate var view: UIView!
    fileprivate var isShowing: Bool = false
    
    weak var delegate: LPNotificationDelegate?
    
    // MARK: - Initializers
    
    init() {
        let screenSize = UIScreen.main.bounds
        let defaultFrame = CGRect(x: CONST.PADDING, y: CONST.HIDDEN_POS, width: screenSize.width - CONST.PADDING * 2, height: CONST.DEFAULT_HEIGHT)
        super.init(frame: defaultFrame)
        commonInit()
    }
    
    deinit {
        print("LPNotification is being deinitialized\n")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    // MARK: - Helper Methods
    
    fileprivate func commonInit() {
        
        loadFromNib()
        
        windowLevel = UIWindowLevelStatusBar + 1.0
        autoresizesSubviews = true
        
        // rounded notification
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        
        view.frame = bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        addSubview(view)
    }
    
    // Loads a XIB file into a view and returns this view
    fileprivate func loadFromNib() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
    }
    
    // Adjust the height to fit with the content
    override func sizeToFit() {
        
        let fixedHeight = vHeader.frame.height + 16.0 // Padding
        
        lbTitle.sizeToFit()
        lbBody.sizeToFit()
        
        let titleFrame = lbTitle.frame
        var bodyFrame = lbBody.frame
        
        var nFrame = frame
        var heigth: CGFloat = 0
        
        
        if (titleFrame.size.height == 0) {
            bodyFrame.origin.y = titleFrame.origin.y
            lbBody.frame = bodyFrame
        }
        heigth = fixedHeight +
            bodyFrame.origin.y +
            bodyFrame.size.height
        
        nFrame.origin.y = CONST.HIDDEN_POS
        nFrame.size.height = heigth
        frame = nFrame
    }
    
    // MARK: - Sound Helpers
    
    fileprivate func playSound() {
        AudioServicesPlayAlertSound(CONST.PUSH_SOUND_ID)
    }
    
    // MARK: - Display Helpers
    
    // set push title, message and redraw the view
    fileprivate func setContent(_ title: String, message: String) {
        if (!title.isEmpty) {
            lbTitle.text = title
        } else {
            lbTitle.text = ""
        }
        lbBody.text = message
        sizeToFit()
        setNeedsDisplay()
    }
    
    // set the y position of the window
    fileprivate func setY(_ y: CGFloat) {
        var newFrame = frame
        newFrame.origin.y = y
        frame = newFrame
    }
    
    fileprivate func displayUI() {
        let slideDown = {
            self.setY(CONST.PADDING)
        }
        let completionHanler = { (finished: Bool) -> () in
            if (finished) {
                self.dismiss(true, delay: CONST.SHOW_DURATION)
            }
        }
        makeKeyAndVisible()
        UIView.animate(withDuration: CONST.SLIDE_DOWN_DURATION, animations: slideDown, completion: completionHanler)
    }
    
    // Remove all animations and hide the window
    fileprivate func hideUI() {
        layer.removeAllAnimations()
        isHidden = true
        setY(CONST.HIDDEN_POS)
        isShowing = false
        delegate?.pushCompleteHandler()
    }
    
    
    // MARK: - Actions
    
    func show(_ title: String, message: String) {
        if (message.isEmpty) {
            return
        }
        playSound()
        if (isShowing) {
            dismiss()
        }
        isShowing = true
        setContent(title, message: message)
        displayUI()
    }
    
    // hide the window after a delay time
    func dismiss(_ animated: Bool, delay: Double) {
        TaskUtil.delay(delay) { [weak self] in
            self?.dismiss(true)
        }
    }
    
    // hide the window immediately, without animation
    func dismiss() {
        dismiss(false)
    }
    
    // hide the window with slide up animation
    func dismiss(_ animated: Bool) {
        if (!isShowing) {
            return
        }
        
        if (animated) {
            let slideUp = {
                self.setY(CONST.HIDDEN_POS)
            }
            let completionHanler = { (finished: Bool) -> () in
                if (finished) {
                    self.hideUI()
                }
            }
            UIView.animate(withDuration: CONST.SLIDE_UP_DURATION, animations: slideUp, completion: completionHanler)
        } else {
            hideUI()
        }
    }
    
    @IBAction func handleTap(_ sender: AnyObject) {
        dismiss()
        delegate?.pushTapHandler()
    }
    
    @IBAction func handleSwipeUp(_ sender: AnyObject) {
        dismiss(true)
    }
}

class TaskUtil {
    static func delay(_ seconds: Double, closure: @escaping ()->()) {
        let delayTime = DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            closure()
        }
    }
}


class LPushManager {
    
    private init() {}
    static let shared = LPushManager()
    private var pushQueue:[LPNotification] = []
    
    func push(p: LPNotification) {
        TaskUtil.delay(LPNotification.CONST.SLIDE_DOWN_DURATION + 0.05) {
            LPushManager.shared.pushQueue.removeAll()
            LPushManager.shared.pushQueue.append(p)
        }
    }
    
    func clean() {
        if (LPushManager.shared.pushQueue.count == 1) {
            LPushManager.shared.pushQueue.removeAll()
        }
    }
}
