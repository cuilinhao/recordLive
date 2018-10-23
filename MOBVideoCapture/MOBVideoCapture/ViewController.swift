//
//  ViewController.swift
//  MOBVideoCapture
//
//  Created by 崔林豪 on 2018/10/16.
//  Copyright © 2018年 崔林豪. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {

    //MARK:- lazy
    //视频
    fileprivate lazy var videoQueue = DispatchQueue.global()
    //音频
    fileprivate lazy var audioQueue = DispatchQueue.global()

    fileprivate lazy var session : AVCaptureSession = AVCaptureSession()
    fileprivate lazy var previewLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    
    //fileprivate var connection : AVCaptureConnection?
    fileprivate var videoOutput : AVCaptureVideoDataOutput?
    
    fileprivate var videoInput : AVCaptureDeviceInput?
    fileprivate var movieOutPut : AVCaptureMovieFileOutput?
    
    fileprivate var connection : AVCaptureConnection?
    
    //MARK:- life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
 
    
}

//MARK:- 视频的开始采集 & 暂停采集
extension ViewController {
    
    @IBAction func starCapture(_ sender: Any) {
        
        //1.设置视频的输入输出
        getVideo()
        
        //2.设置音频的输入和x输出
        getAudio()
        
        //3.添加写入文件的output
        //MARK:- >>>>>>>>>>>第二次开始采集奔溃>>>>>>>>>
        let movieOutput = AVCaptureMovieFileOutput()
        
        //---
        if let outputs = session.outputs as [AVCaptureOutput]? {
            
            for output in outputs {
                
                session.removeOutput(output)
            }
        }
        
        
        if session.outputs.isEmpty {
           session.addOutput(movieOutput)
        }
        
         self.movieOutPut = movieOutput
        
        //设置写入的稳定性
        let connection = movieOutput.connection(with: AVMediaType.video)
        connection?.preferredVideoStabilizationMode = .auto
        
        self.connection = connection
        
        
        //4.给用户看到一个预览图层
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        view.layer .insertSublayer(previewLayer, at: 0)
        
        //5.开始采集
        session.startRunning()
        
        //6.开始录制
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/abc.mp4"
        
        let url = URL(fileURLWithPath: path)
        
        movieOutput.startRecording(to: url, recordingDelegate: self)
        
    }
    
    @IBAction func stopCapture(_ sender: Any) {
        
        self.movieOutPut?.stopRecording()
        
        session.stopRunning()
        previewLayer.removeFromSuperlayer()
    }
    
    //切换摄像头
    @IBAction func changeCamerPostion(_ sender: Any) {
        
        switchScence()
    }
    
}

extension ViewController {
    
    func getVideo () {
        //1.创建捕捉会话
        //let session = AVCaptureSession()
        
        //2.给捕捉会话设置输入源(摄像头)
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as [AVCaptureDevice]? else {
            print("摄像头不可用")
            return
        }
        
        /*
         var device: AVCaptureDevice!
         for d in devices {
         if d.position == .front {
         device = d
         break
         }
         }
         guard let device = devices.filter({$0.position == .front }).first else {
         return
         }
         */
        //MARK:- -----------拿到前置摄像头--------------------------
        //2.1拿到前置摄像头
        let device = devices.filter { (device : AVCaptureDevice) -> Bool in
            return device.position == .front
            }.first
        
        //2.2通过device创建AVCaptureInput对象 抛出异常
        guard let videoInput = try? AVCaptureDeviceInput(device: device!) else {
            return
        }
        
        self.videoInput = videoInput
        
        //2.3 将input 添加到会话
        //MARK:- *******第二次添加的时候会奔溃*******************
        
        //session.addInput(videoInput)
        
        if let inputs = session.inputs as? [AVCaptureDeviceInput] {
         
            for input in inputs {
             
                session.removeInput(input)
            }
        }
        
        if session.inputs.isEmpty {
            
            session.addInput(videoInput)
        }
        
        
        //3.给捕捉会话设置输出源
        //session.addOutput(nil)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate?, queue: videoQueue)
        
        if let outputs = session.outputs as [AVCaptureOutput]? {
            
            for output in outputs {
                
                session.removeOutput(output)
            }
        }
        
        
        if session.outputs.isEmpty {
            session.addOutput(videoOutput)
        }
        
        
        //connection = videoOutput.connection(with: AVMediaType.video)
        
        self.videoOutput = videoOutput
    }
    
    
   fileprivate func getAudio() {
        //1. 设置音频的输入(话筒)
        //1.1获取话筒设备
    guard  let device = AVCaptureDevice.default(for: AVMediaType.audio) else {
        return
    }
    // 1.2根据device创建AVcaptureInput
    guard let audioInput = try? AVCaptureDeviceInput(device: device) else {
        return
    }
    
    //1.3 将input 添加到会话中
    session.addInput(audioInput)
    
    //2. 给会话设置音频输出源
    let audioOutPut = AVCaptureAudioDataOutput()
    audioOutPut.setSampleBufferDelegate(self as? AVCaptureAudioDataOutputSampleBufferDelegate, queue: audioQueue)
    
    if let outputs = session.outputs as [AVCaptureOutput]? {
        
        for output in outputs {
            
            session.removeOutput(output)
        }
    }
    
    
    if session.outputs.isEmpty {
        
         session.addOutput(audioOutPut)
    }
   
    
    
   }
    
    func switchScence() {
        
        //1. 获取之前的摄像头
        guard var position = videoInput?.device.position else {
            
            return
        }
        
        //2.获取当前应该显示的镜头
        position = position == .front ? .back : .front
        
        //3.根据当前镜头创建新的Device
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        let device = devices.filter({ (device : AVCaptureDevice) -> Bool in
            
            return device.position == position
            
        }).first
        
        //4.根据新的Device创建新的input
        guard let videoInput = try? AVCaptureDeviceInput(device: device!) else {
         
            return
        }
        
        //5.在session中切换input
        session.beginConfiguration()
        
        session.removeInput(self.videoInput!)
        session.addInput(videoInput)
        self.connection?.preferredVideoStabilizationMode = .auto
        session.commitConfiguration()
        
        self.videoInput = videoInput
        
        
    }
    
}
    
extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if connection == videoOutput?.connection(with: AVMediaType.video)
        {
             print("------已经采集视频画面")
        }
        else
        {
            print("++++++++已经采集音频画面")
         }
        
    }
}

extension ViewController : AVCaptureFileOutputRecordingDelegate {

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("----开始写入文件")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
         print("----结束写入文件")
    }
}

