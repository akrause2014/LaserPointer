//
//  ViewController.swift
//  LaserPointer
//
//  Created by Amy Krause on 10/02/2018.
//  Copyright © 2018 Amy Krause. All rights reserved.
//

import UIKit
import CoreMotion
import CoreBluetooth

let TRANSFER_SERVICE_UUID = "B07172BF-BDD4-4B1A-9F45-D72B3AFF3207"
let TRANSFER_SERVICE_CBUUID = CBUUID(string: TRANSFER_SERVICE_UUID)

let TRANSFER_CHARACTERISTIC_UUID = "4C0FA8BE-45C9-4D8A-B529-CCCF5E7A50B8"

let motionManager = CMMotionManager()
let NOTIFY_MTU = 20

func degrees(radians:Double) -> Double {
    return 180 / .pi * radians
}

class ViewController: UIViewController, CBPeripheralManagerDelegate {

    @IBOutlet weak var rollLabel: UILabel!
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var yawLabel: UILabel!
    
    @IBOutlet weak var ConnectButton: UIButton!
    
    var peripheralManager : CBPeripheralManager?
    var transferCharacteristic : CBMutableCharacteristic?
    var hasSubscribers = false
    
    @IBAction func connect(_ sender: Any) {
        NSLog("Connect button pressed")
        peripheralManager = CBPeripheralManager.init(delegate: self, queue: nil)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        NSLog("%@ did subscribe to characteristic", central)
        self.hasSubscribers = true
        self.sendData("test")
    }
    
    func sendData(_ dataToSend: String) {
        let asData = dataToSend.data(using:.utf8)
        
//        let didSend =
            peripheralManager?.updateValue(asData!, for:self.transferCharacteristic!, onSubscribedCentrals:nil)
        
//        print("Data sent: ", didSend!)

    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("Peripheral manager did update state")
        peripheral.stopAdvertising()
        
        switch peripheral.state{
        case .poweredOff:
            print("Powered off")
        case .poweredOn:
            print("Powered on")
        case .resetting:
            print("Resetting")
        case .unauthorized:
            print("Unauthorized")
        case .unknown:
            print("Unknown")
        case .unsupported:
            print("Unsupported")
        }
        
        /* Bluetooth is now powered on */
        if peripheral.state != .poweredOn{
            
            let controller = UIAlertController(title: "Bluetooth",
                                               message: "Please turn Bluetooth on",
                                               preferredStyle: .alert)
            
            controller.addAction(UIAlertAction(title: "OK",
                                               style: .default,
                                               handler: nil))
            
            present(controller, animated: true, completion: nil)
            
        } else {
            
            let dataToBeAdvertised:[String: Any] = [
                CBAdvertisementDataServiceUUIDsKey : [CBUUID(string:TRANSFER_SERVICE_UUID)],
                ]
            
            peripheral.startAdvertising(dataToBeAdvertised)

            self.transferCharacteristic = CBMutableCharacteristic(type: CBUUID(string:TRANSFER_CHARACTERISTIC_UUID), properties: CBCharacteristicProperties.notify, value:nil, permissions: CBAttributePermissions.readable)
            
            let transferService = CBMutableService(type: CBUUID(string:TRANSFER_SERVICE_UUID), primary: true)
            
            transferService.characteristics = [self.transferCharacteristic!]
            
            peripheral.add(transferService)
            
        }
        

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(
                to: OperationQueue.current!, withHandler: {
                    (deviceMotion, error) -> Void in
                    
                    if(error == nil) {
                        let attitude = deviceMotion?.attitude
                        let roll = degrees(radians: (attitude?.roll)!)
                        let pitch = degrees(radians: (attitude?.pitch)!)
                        let yaw = degrees(radians: (attitude?.yaw)!)
                        self.rollLabel.text = String(roll)
                        self.pitchLabel.text = String(pitch)
                        self.yawLabel.text = String(yaw)
                        if (self.hasSubscribers) {
                            let s = String(Int(roll)) + "," + String(Int(pitch)) + "," + String(Int(yaw))
                            self.sendData(s)
                        }
                    } else {
                        //handle the error
                    }
            })
            motionManager.deviceMotionUpdateInterval = 0.1
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

