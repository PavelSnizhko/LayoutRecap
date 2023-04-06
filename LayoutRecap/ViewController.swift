//
//  ViewController.swift
//  LayoutRecap
//
//  Created by Павло Сніжко on 05.04.2023.
//

import UIKit

class ViewController: UIViewController {

    private var containerView = UIView()
    
    private var backgroundLayer: CAShapeLayer?
    private var progressLayer: CAShapeLayer?
    
    private lazy var stackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        return stackView
    }()
    
    
    private let progressTextField = UITextField()
    private let durationTextField = UITextField()
    private let startAnimationButton = UIButton(type: .system)
    
    private var counterStartValue = 0
    private var counterEndValue = 0
    private var counterDuration: TimeInterval = 0
    private var counterDispayLink: CADisplayLink?
    private var counterStartDate: Date?

    private var progressLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.text = "0"
        label.font = .boldSystemFont(ofSize: 40)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayerPaths()
    }
    
    private func updateLayerPaths() {
        let center = CGPoint(x: containerView.bounds.midX, y: containerView.bounds.midY)
        self.backgroundLayer?.path = configureProgressBarPath(center: center)
        self.progressLayer?.path = configureProgressBarPath(center: center)
    }
    
    func setUI() {
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 200),
            containerView.widthAnchor.constraint(equalToConstant: 200),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        containerView.center = view.center
        
        containerView.addSubview(progressLabel)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            progressLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    
        setUpBackgroundLayer()
        setUpProgressLayer()
        
        setupInputViews()
    }
    
    // MARK: - CAShapeLayer configuration

    private func configureBackgroundLayer() -> CAShapeLayer {
        let backgroundLayer = CAShapeLayer()
        
        backgroundLayer.path = configureProgressBarPath(center: containerView.center)
        backgroundLayer.strokeColor = UIColor.lightGray.cgColor
        backgroundLayer.lineWidth = 20
        backgroundLayer.lineCap = .round
        backgroundLayer.fillColor = nil
        
        return backgroundLayer
    }
    
    private func configureProgressLayer() -> CAShapeLayer {
        let progressLayer = CAShapeLayer()

        progressLayer.path = configureProgressBarPath(center: containerView.center)
        progressLayer.strokeColor = UIColor.lightGray.cgColor
        progressLayer.lineWidth = 20
        progressLayer.lineCap = .round
        progressLayer.fillColor = nil
        progressLayer.strokeEnd = 0

        return progressLayer
    }
    
    private func configureProgressBarPath(center: CGPoint) -> CGPath {
        let endAngle = CGFloat.pi / 4
        let startAngle = 3 * CGFloat.pi / 4
        
        return UIBezierPath(arcCenter: center,
                            radius: 100 - 8,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: true).cgPath
    }
    

    
    private func resetLabelAnimation() {
        counterDispayLink?.invalidate()
        counterDispayLink = nil
        
        counterStartDate = nil
        progressLabel.text = "0"
    }
    
    // MARK: - Animation

    private func startAnimation(drivingStyleRating: Int, duration: TimeInterval) {
        resetProgressBar()
        setProgressLayerAnimation(for: drivingStyleRating, and: duration)
        setLabelCountingAnimation(for: drivingStyleRating, and: duration)
    }
    
    private func resetProgressBar() {
        progressLayer?.strokeEnd = 0
        progressLayer?.removeAllAnimations()
        progressLayer?.strokeColor = nil
        
        resetLabelAnimation()
    }
    
    private func setUpProgressLayer() {
        let progressLayer = configureProgressLayer()
        containerView.layer.insertSublayer(progressLayer, above: backgroundLayer)
        self.progressLayer = progressLayer
    }
    
    private func setUpBackgroundLayer() {
        let backgroundLayer = configureBackgroundLayer()
        containerView.layer.addSublayer(backgroundLayer)
        self.backgroundLayer = backgroundLayer
    }
    
    private func setProgressLayerAnimation(for drivingStyleRating: Int, and duration: TimeInterval) {
        
        let progress = CGFloat(drivingStyleRating) / 100.0
        
        //to have a progress after animation
        progressLayer?.strokeEnd = progress
        
        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        
        strokeEndAnimation.fromValue = 0
        strokeEndAnimation.toValue = progress
        strokeEndAnimation.duration = duration
        
        progressLayer?.add(strokeEndAnimation, forKey: "strokeEndAnimation")
        
        
        let colors = getColors(for: drivingStyleRating)
        
        progressLayer?.strokeColor = colors.last
        
        let strokeColorAnimation = CAKeyframeAnimation(keyPath: "strokeColor")
        strokeColorAnimation.values = colors
        strokeColorAnimation.duration = duration
        
        progressLayer?.add(strokeColorAnimation, forKey: "strokeColorAnimation")
    }
    
    private func getColors(for progress: Int) -> [CGColor] {
        let startColor = UIColor.red
        let endColor = UIColor.green

        var colorValues = [CGColor]()
        
        for i in 0...progress {
            let progress = CGFloat(i) / 100.0
            let color = UIColor.interpolateColor(from: startColor, to: endColor, with: progress).cgColor
            colorValues.append(color)
        }
        
        return colorValues
    }
    
    private func setLabelCountingAnimation(for drivingStyleRating: Int, and duration: TimeInterval) {
        counterDuration = duration
        counterStartValue = 0
        counterEndValue = drivingStyleRating
        
        let displayLink = CADisplayLink(target: self, selector: #selector(handleCounterUpdate))
        displayLink.add(to: .main, forMode: .default)
        
        counterDispayLink = displayLink
        counterStartDate = Date()
    }
    
    @objc private func handleCounterUpdate() {
        guard let startDate = counterStartDate else {
            return
        }
        
        let elapsedTime = Date().timeIntervalSince(startDate)
        
        guard elapsedTime < counterDuration else {
            counterDispayLink?.invalidate()
            counterDispayLink = nil
            counterStartDate = nil
            progressLabel.text = "\(counterEndValue)"
            
            return
        }
        
        let percentage = elapsedTime / counterDuration
        let value = Double(counterStartValue) + percentage * Double(counterEndValue - counterStartValue)
        
        progressLabel.text = "\(Int(value.rounded()))"
    }
}

//MARK: Input Views

extension ViewController {
    
    private func setupInputViews() {
        progressTextField.placeholder = "Enter progress"
        progressTextField.borderStyle = .roundedRect

        durationTextField.placeholder = "Enter duration"
        durationTextField.borderStyle = .roundedRect

        startAnimationButton.setTitle("Start animation", for: .normal)
        startAnimationButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        [progressTextField, durationTextField, startAnimationButton].forEach(stackView.addArrangedSubview)
        view.addSubview(stackView)
        
        setupInputViewsConstraints()
    }

    private func setupInputViewsConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalToConstant: 300)
        ])
    }

    @objc func buttonTapped() {
        guard let rawDuration = durationTextField.text,
              let rawProgress = progressTextField.text else {
            return
        }
        
        let duration = TimeInterval(Int(rawDuration) ?? 1)
        let progress = Int(rawProgress) ?? 100
        
        startAnimation(drivingStyleRating: progress, duration: duration)
    }
}

//MARK: Color interpolation

extension UIColor {
    
    static func interpolateColor(from startColor: UIColor, to endColor: UIColor, with progress: CGFloat) -> UIColor {
        let startComponents = startColor.cgColor.components ?? []
        let endComponents = endColor.cgColor.components ?? []
        let componentsCount = max(startComponents.count, endComponents.count)
        var interpolatedComponents = [CGFloat]()
        
        for i in 0..<componentsCount {
            let startComponent = i < startComponents.count ? startComponents[i] : 0
            let endComponent = i < endComponents.count ? endComponents[i] : 0
            let interpolatedComponent = startComponent + (endComponent - startComponent) * progress
            interpolatedComponents.append(interpolatedComponent)
        }
        
        return UIColor(red: interpolatedComponents[0], green: interpolatedComponents[1], blue: interpolatedComponents[2], alpha: interpolatedComponents[3])
    }
    
}

