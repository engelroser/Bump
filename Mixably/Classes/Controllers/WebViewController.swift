//
//  MIWebViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 12/04/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit
import WebKit
import WebKitPlus

class MIWebViewController: UIViewController {

    var webView: WKWebView!
    
    @IBOutlet weak var progressBar: UIProgressView!
    public lazy var UIDelegate: WKUIDelegatePlus = WKUIDelegatePlus(parentViewController: self)
    public lazy var observer: WebViewObserver = WebViewObserver(obserbee: self.webView)
    
    open var url : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        
        
        // Do any additional setup after loading the view.
    }
    
    func setupUI() {
        
        view.backgroundColor = Color.TUTORIAL_BACKGROUND_TOP
        
        webView = WKWebView()
        webView.uiDelegate = UIDelegate
        observer.onProgressChanged = updateProgress
        observer.onLoadingStatusChanged = updateStatus
        
        view.addSubview(webView)
        webView.snp.makeConstraints{(make) -> Void in
            
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalToSuperview().offset(62)
            make.bottom.equalToSuperview()
        }
        
        
        if let myURL = URL(string: url){
            
            let myRequest = URLRequest(url: myURL)
            webView.load(myRequest)
            
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func updateProgress(_ progress: Double) {
        progressBar.progress = Float(progress)
    }
    
    func updateStatus(_ loading: Bool) {
        progressBar.isHidden = !loading
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func onClickBtnDone(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
