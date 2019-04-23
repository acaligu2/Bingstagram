//
//  ViewController.swift
//  Bingstagram
//
//  Created by Anthony on 4/10/19.
//  Copyright © 2019 CaligureForno. All rights reserved.
//

import UIKit
import MultipeerConnectivity


class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    var images = [UIImage]()
    
    //NodeID
    var peer_id: MCPeerID!
    
    //Manager class that handles all of multipeer stuff
    var mc_session: MCSession!
    
    //class used to create a session and let other devices around know
    var mcaa: MCAdvertiserAssistant!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        title = "Bingstagram"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        // Do any additional setup after loading the view, typically from a nib.
        //create a connection button
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        
        //creating peer id
        peer_id = MCPeerID(displayName: UIDevice.current.name)
        //creating session
        mc_session = MCSession(peer: peer_id, securityIdentity: nil, encryptionPreference: .required)
        mc_session.delegate = self
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        
        return images.count
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)
        
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
         
            imageView.image = images[indexPath.item]
            
        }
        
        return cell
        
    }
    
    //Begin hosting a session for others to join
    func startHosting(action: UIAlertAction) {
        mcaa = MCAdvertiserAssistant(serviceType: "bingstagram", discoveryInfo: nil, session: mc_session)
        mcaa.start()
    }
    
    //Connect to specified session
    func joinSession(action: UIAlertAction) {
        let mc_browser = MCBrowserViewController(serviceType: "bingstagram", session: mc_session)
        mc_browser.delegate = self
        present(mc_browser, animated: true)
    }
    
    // When the button is pressed, it gives you a list of options
    // to either join or host a photosharing session
    @IBAction func showConnectionPrompt(_ sender: Any) {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Host a BingSession", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a BingSession", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {  }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        switch state {
            
            case MCSessionState.connected:
                NSLog("Connected: \(peerID.displayName)")
            
            case MCSessionState.connecting:
                NSLog("Connecting: \(peerID.displayName)")
            
            case MCSessionState.notConnected:
                NSLog("Not Connected: \(peerID.displayName)")
            
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let image = UIImage(data: data) {
            DispatchQueue.main.async{
                [unowned self] in
                    self.images.insert(image, at: 0)
                    self.collectionView?.reloadData()
            }
        }
    }
    
    func sendImage(img: UIImage){
        
        if mc_session.connectedPeers.count > 0 {
            
            if let imageData = img.pngData() {
                
                do {
                    
                    try mc_session.send(imageData, toPeers: mc_session.connectedPeers, with: .reliable)
                    
                } catch {
                    
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    present(ac, animated: true)
                    
                }
            }
            
        }
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
        //browserViewController.dismiss(animated: true, completion: nil)
        //dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
        //browserViewController.dismiss(animated: true, completion: nil)
        //dismiss(animated: true)
    }
    
    
    @objc func importPicture(){
        
        let imageSelection = UIImagePickerController()
        imageSelection.delegate = self
        imageSelection.allowsEditing = true
        
        //Allow the user to pick the camera or photo library
        let actionSheet = UIAlertController(title: "Photo Source", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
                imageSelection.sourceType = .camera
                self.present(imageSelection, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
                imageSelection.sourceType = .photoLibrary
                self.present(imageSelection, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))

        //Present the action sheet with options
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    //Send the data associated with the selected photo
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.editedImage] as? UIImage else { return }
        
        dismiss(animated: true)
        
        images.insert(image, at: 0)
        collectionView?.reloadData()
        
        if mc_session.connectedPeers.count > 0 {
            
            if let imageData = image.pngData() {
                
                do {
                    
                    try mc_session.send(imageData, toPeers: mc_session.connectedPeers, with: .reliable)
                    
                } catch {
                    
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    present(ac, animated: true)
                    
                }
            }
        }
        
    }


}

