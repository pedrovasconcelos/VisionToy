//
//  VisionToyViewController.swift
//  VisionToy
//
//  Created by Pedro Vasconcelos on 02/03/2018.
//  Copyright © 2018 Pedro Vasconcelos. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class VisionToyViewController: UIViewController {

    // MARK: Properties
    
    // Data source for objects identified in current video frame.
    private var currentClassifications: [Classification] = []
    
    private var imageAnalysisRequests: [VNRequest] = []
    
    // A preview layer is used to display video directly as it is being captured in a capture session.
    private var cameraLayer: AVCaptureVideoPreviewLayer?
    private var captureSession: AVCaptureSession?
    
    // A timer is used to control which updates from the video buffer should trigger an image analysis request.
    private let analysisTimePeriod: TimeInterval = 1 // seconds
    private var timer: Timer = Timer()
    private var visionShouldUpdate = true
    
    // If audio is enabled, objects identified in the video stream will be converted to speech.
    // This flag is controlled via the UI
    private var isAudioEnabled = true
    
    // Text to speech service
    private let ttsMachine = TTSMachine()
    
    // MARK: IBOutlets
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var audioToggleButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupVideoCapture()
        setupVision()
        
        timer = Timer.scheduledTimer(withTimeInterval: analysisTimePeriod, repeats: true, block: { timer in
            self.visionShouldUpdate = true
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraLayer?.frame = CGRect(origin: .zero, size: cameraView.bounds.size)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // MARK: - IBActions
    
    @IBAction func audioToggleButtonTapped(_ sender: UIButton) {
        if isAudioEnabled {
            audioToggleButton.setTitle("Audio OFF", for: .normal)
            isAudioEnabled = false
            ttsMachine.stopSpeaking()
        } else {
            audioToggleButton.setTitle("Audio ON", for: .normal)
            isAudioEnabled = true
        }
    }
    
    // MARK: - Private methods
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        
        // Add blurred background
        tableView.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        tableView.backgroundView = blurView
    }
    
    private func setupVideoCapture() {
        // Create and configure a capture session.
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        // Setup an input for this capture session (the back camera).
        guard let backCamera = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCamera)
            else { return }
        captureSession.addInput(input)
        
        // Setup an output for this capture session.
        // The buffer delegate is the object that will handle frame updates from the video output.
        // The processing done by the delegate is executed in the queue specified here.
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        captureSession.addOutput(videoOutput)
        
        // Setup a video preview layer using the capture session
        cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        // Configure the video preview layer to take up all the available size in its view
        cameraLayer?.videoGravity = .resizeAspectFill
        if let cameraLayer = cameraLayer {
            cameraView?.layer.addSublayer(cameraLayer)
        }
        
        // Start capturing
        captureSession.startRunning()
    }
    
    private func setupVision() {
        // Get the Core ML model to be used for the Vision image analysis request.
        guard let visionModel = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Can't load CoreML model.")
        }
        
        // Create and configure the image analysis request. Store it for later use.
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: didCompleteClassification)
        classificationRequest.imageCropAndScaleOption = .centerCrop
        imageAnalysisRequests = [classificationRequest]
    }
    
    // Completion handler for image analysis requests.
    private func didCompleteClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results else { return }
        
        let newClassifications: [Classification]
        
        // Convert observations from the Vision request into custom, simpler, Classification objects.
        do {
            let topObservations = observations[0...10].flatMap({ $0 as? VNClassificationObservation })
            let filteredObservations = topObservations.filter({ $0.confidence >= 0.1 })
            let observationsSortedByConfidence = filteredObservations.sorted(by: { $0.confidence > $1.confidence })
            let classificationObjects = observationsSortedByConfidence.map {
                (classificationObservation: VNClassificationObservation) -> Classification in
                let pastConfidence: Double
                if let existingClassification = currentClassifications.first(where: { $0.identifier == classificationObservation.identifier }) {
                    pastConfidence = existingClassification.confidence
                } else {
                    pastConfidence = 0
                }
                return Classification(identifier: classificationObservation.identifier, pastConfidence: pastConfidence, confidence: Double(classificationObservation.confidence))
            }
            newClassifications = classificationObjects
        }
        
        // Calculate updates to be made to the table view (deletions, insertions, moves and reloads).
        let tableViewUpdates = calculateTableViewUpdates(from: currentClassifications, to: newClassifications)
        
        // This handler is not executed on the main queue so we must tell it to do so explicitly.
        DispatchQueue.main.async {
            // Update the data source and perform the necessary updates to the table view
            self.currentClassifications = newClassifications
            self.tableView.performBatchUpdates({
                self.tableView.deleteRows(at: tableViewUpdates.deletions, with: .fade)
                self.tableView.insertRows(at: tableViewUpdates.insertions, with: .fade)
                for move in tableViewUpdates.moves {
                    self.tableView.moveRow(at: move.from, to: move.to)
                }
                
            }, completion: { complete in
                // Items that were present in the old data source and are also present in the new one, will need reloading.
                // These items may or may not change position in the data source so we wait for batch updates to complete.
                self.tableView.reloadRows(at: tableViewUpdates.reloads, with: .none)
            })
        }
        
        if isAudioEnabled {
            if let firstClassification = newClassifications.first {
                ttsMachine.speak(text: firstClassification.identifier)
            } else {
                ttsMachine.stopSpeaking()
            }
        }
    }
    
    private func calculateTableViewUpdates(from oldDataSource: [Classification], to newDataSource: [Classification]) -> (deletions: [IndexPath], insertions: [IndexPath], moves: [(from: IndexPath, to: IndexPath)], reloads: [IndexPath]) {
        var indexPathsToDelete: [IndexPath] = []
        var indexPathsToInsert: [IndexPath] = []
        var indexPathsToMove: [(from: IndexPath, to: IndexPath)] = []
        var indexPathsToReload: [IndexPath] = []
        
        // Deletions - Items present in the old data source but not in the new one, are marked for deletion.
        for (oldIndex, oldClassification) in oldDataSource.enumerated() {
            if !newDataSource.contains(where: { $0.identifier == oldClassification.identifier }) {
                let indexPath = IndexPath(row: oldIndex, section: 0)
                indexPathsToDelete.append(indexPath)
            }
        }
        
        // Insertions - Items present in the new data source but not in the old one, are marked for insertion
        for (newIndex, newClassification) in newDataSource.enumerated() {
            if !oldDataSource.contains(where: { $0.identifier == newClassification.identifier }) {
                let indexPath = IndexPath(row: newIndex, section: 0)
                indexPathsToInsert.append(indexPath)
            }
        }
        
        // Moves and reloads - Items present in the old data source, which are also present in the new one, are marked for reloading.
        // If an item's index changes between old and new data source, then it's also marked to be moved.
        for (newIndex, newClassification) in newDataSource.enumerated() {
            if let oldIndex = oldDataSource.index(where: { $0.identifier == newClassification.identifier }) {
                let newIndexPath = IndexPath(row: newIndex, section: 0)
                indexPathsToReload.append(newIndexPath)
                
                if oldIndex != newIndex {
                    let oldIndexPath = IndexPath(row: oldIndex, section: 0)
                    indexPathsToMove.append((from: oldIndexPath, to: newIndexPath))
                }
            }
        }
        
        return (deletions: indexPathsToDelete, insertions: indexPathsToInsert, moves: indexPathsToMove, reloads: indexPathsToReload)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VisionToyViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    // This is called whenever a new video frame is captured.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard visionShouldUpdate else { return }
        visionShouldUpdate = false
        
        // Retrieve the image buffer from the sample buffer.
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Configure the Vision request handler with data from the newly captured frame.
        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions[.cameraIntrinsics] = cameraIntrinsicData
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: requestOptions)
        
        // Use the handler to perform the request that we already configured when the view loaded.
        do {
            try imageRequestHandler.perform(imageAnalysisRequests)
        } catch {
            print(error)
        }
    }
}

// MARK: - UITableViewDataSource

extension VisionToyViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentClassifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ClassificationTableViewCell", for: indexPath) as? ClassificationTableViewCell else { return UITableViewCell() }
        
        let classification = currentClassifications[indexPath.row]
        
        // Here we configure the cell with the old confidence value, so we can animate the update in tableView(_:willDisplay:forRowAt:)
        cell.configureFor(classification: classification.identifier, confidence: CGFloat(classification.pastConfidence))
        return cell
    }
}

// MARK: - UITableViewDelegate

extension VisionToyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ClassificationTableViewCell else { return }
        
        let classification = currentClassifications[indexPath.row]
        
        // Here we configure the cell the current confidence value and animate the change
        cell.configureFor(classification: classification.identifier, confidence: CGFloat(classification.confidence))
        UIView.animate(withDuration: 1, delay: 0, options: [.beginFromCurrentState], animations: {
            cell.layoutIfNeeded()
        }, completion: nil)
    }
}
