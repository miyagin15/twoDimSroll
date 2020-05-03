//
// Copyright © 2017 Gavrilov Daniil
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import UIKit

// MARK: Class Definition

/// Performance view. Displays performance information above status bar. Appearance and output can be changed via properties.
internal class PerformanceView: UIWindow, PerformanceViewConfigurator {
    // MARK: Structs

    private struct Constants {
        static let prefferedHeight: CGFloat = 20.0
        static let borderWidth: CGFloat = 1.0
        static let cornerRadius: CGFloat = 5.0
        static let pointSize: CGFloat = 8.0
        static let defaultStatusBarHeight: CGFloat = 20.0
        static let safeAreaInsetDifference: CGFloat = 11.0
    }

    // MARK: Public Properties

    /// Allows to change the format of the displayed information.
    public var options = PerformanceMonitor.DisplayOptions.default {
        didSet {
            configureStaticInformation()
        }
    }

    public var userInfo = PerformanceMonitor.UserInfo.none {
        didSet {
            configureUserInformation()
        }
    }

    /// Allows to change the appearance of the displayed information.
    public var style = PerformanceMonitor.Style.dark {
        didSet {
            configureView(withStyle: style)
        }
    }

    /// Allows to add gesture recognizers to the view.
    public var interactors: [UIGestureRecognizer]? {
        didSet {
            configureView(withInteractors: interactors)
        }
    }

    // MARK: Private Properties

    private let monitoringTextLabel = MarginLabel()
    private var staticInformation: String?
    private var userInformation: String?

    // MARK: Init Methods & Superclass Overriders

    internal required init() {
        super.init(frame: PerformanceView.windowFrame(withPrefferedHeight: Constants.prefferedHeight))

        configureWindow()
        configureMonitoringTextLabel()
        subscribeToNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layoutWindow()
    }

    override func becomeKey() {
        isHidden = true

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.showViewAboveStatusBarIfNeeded()
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let interactors = self.interactors, interactors.count > 0 else {
            return false
        }
        return super.point(inside: point, with: event)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: Public Methods

internal extension PerformanceView {
    /// Hides monitoring view.
    func hide() {
        monitoringTextLabel.isHidden = true
    }

    /// Shows monitoring view.
    func show() {
        monitoringTextLabel.isHidden = false
    }

    /// Updates monitoring label with performance report.
    ///
    /// - Parameter report: Performance report.
    func update(withPerformanceReport report: PerformanceReport) {
        var monitoringTexts: [String] = []
        if options.contains(.performance) {
            let performance = String(format: "CPU: %.1f%%, FPS: %d", report.cpuUsage, report.fps)
            monitoringTexts.append(performance)
        }

        if options.contains(.memory) {
            let bytesInMegabyte = 1024.0 * 1024.0
            let usedMemory = Double(report.memoryUsage.used) / bytesInMegabyte
            let totalMemory = Double(report.memoryUsage.total) / bytesInMegabyte
            let memory = String(format: "%.1f of %.0f MB used", usedMemory, totalMemory)
            monitoringTexts.append(memory)
        }

        if let staticInformation = self.staticInformation {
            monitoringTexts.append(staticInformation)
        }

        if let userInformation = self.userInformation {
            monitoringTexts.append(userInformation)
        }

        monitoringTextLabel.text = (monitoringTexts.count > 0 ? monitoringTexts.joined(separator: "\n") : nil)
        showViewAboveStatusBarIfNeeded()
        layoutMonitoringLabel()
    }
}

// MARK: Notifications & Observers

private extension PerformanceView {
    func applicationWillChangeStatusBarFrame(notification _: Notification) {
        layoutWindow()
    }
}

// MARK: Configurations

private extension PerformanceView {
    func configureWindow() {
        rootViewController = WindowViewController()
        windowLevel = UIWindow.Level.statusBar + 1.0
        backgroundColor = .clear
        clipsToBounds = true
        isHidden = true
    }

    func configureMonitoringTextLabel() {
        monitoringTextLabel.textAlignment = NSTextAlignment.center
        monitoringTextLabel.numberOfLines = 0
        monitoringTextLabel.clipsToBounds = true
        addSubview(monitoringTextLabel)
    }

    func configureStaticInformation() {
        var staticInformations: [String] = []
        if options.contains(.application) {
            let applicationVersion = self.applicationVersion()
            staticInformations.append(applicationVersion)
        }
        if options.contains(.device) {
            let deviceModel = self.deviceModel()
            staticInformations.append(deviceModel)
        }
        if options.contains(.system) {
            let systemVersion = self.systemVersion()
            staticInformations.append(systemVersion)
        }

        staticInformation = (staticInformations.count > 0 ? staticInformations.joined(separator: ", ") : nil)
    }

    func configureUserInformation() {
        var staticInformation: String?
        switch userInfo {
        case .none:
            break
        case let .custom(string):
            staticInformation = string
        }

        userInformation = staticInformation
    }

    func subscribeToNotifications() {
        NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarFrameNotification, object: nil, queue: .main) { [weak self] notification in
            self?.applicationWillChangeStatusBarFrame(notification: notification)
        }
    }

    func configureView(withStyle style: PerformanceMonitor.Style) {
        switch style {
        case .dark:
            monitoringTextLabel.backgroundColor = .black
            monitoringTextLabel.layer.borderColor = UIColor.white.cgColor
            monitoringTextLabel.layer.borderWidth = Constants.borderWidth
            monitoringTextLabel.layer.cornerRadius = Constants.cornerRadius
            monitoringTextLabel.textColor = .white
            monitoringTextLabel.font = UIFont.systemFont(ofSize: Constants.pointSize)
        case .light:
            monitoringTextLabel.backgroundColor = .white
            monitoringTextLabel.layer.borderColor = UIColor.black.cgColor
            monitoringTextLabel.layer.borderWidth = Constants.borderWidth
            monitoringTextLabel.layer.cornerRadius = Constants.cornerRadius
            monitoringTextLabel.textColor = .black
            monitoringTextLabel.font = UIFont.systemFont(ofSize: Constants.pointSize)
        case let .custom(backgroundColor, borderColor, borderWidth, cornerRadius, textColor, font):
            monitoringTextLabel.backgroundColor = backgroundColor
            monitoringTextLabel.layer.borderColor = borderColor.cgColor
            monitoringTextLabel.layer.borderWidth = borderWidth
            monitoringTextLabel.layer.cornerRadius = cornerRadius
            monitoringTextLabel.textColor = textColor
            monitoringTextLabel.font = font
        }
    }

    func configureView(withInteractors interactors: [UIGestureRecognizer]?) {
        if let recognizers = self.gestureRecognizers {
            for recognizer in recognizers {
                removeGestureRecognizer(recognizer)
            }
        }

        if let recognizers = interactors {
            for recognizer in recognizers {
                addGestureRecognizer(recognizer)
            }
        }
    }
}

// MARK: Layout View

private extension PerformanceView {
    func layoutWindow() {
        frame = PerformanceView.windowFrame(withPrefferedHeight: monitoringTextLabel.bounds.height)
        layoutMonitoringLabel()
    }

    func layoutMonitoringLabel() {
        let windowWidth = bounds.width
        let windowHeight = bounds.height
        let labelSize = monitoringTextLabel.sizeThatFits(CGSize(width: windowWidth, height: CGFloat.greatestFiniteMagnitude))

        if windowHeight != labelSize.height {
            frame = PerformanceView.windowFrame(withPrefferedHeight: monitoringTextLabel.bounds.height)
        }

        monitoringTextLabel.frame = CGRect(x: (windowWidth - labelSize.width) / 2.0, y: (windowHeight - labelSize.height) / 2.0, width: labelSize.width, height: labelSize.height)
    }
}

// MARK: Support Methods

private extension PerformanceView {
    func showViewAboveStatusBarIfNeeded() {
        guard UIApplication.shared.applicationState == UIApplication.State.active, canBeVisible(), isHidden else {
            return
        }
        isHidden = false
    }

    func applicationVersion() -> String {
        var applicationVersion = "<null>"
        var applicationBuildNumber = "<null>"
        if let infoDictionary = Bundle.main.infoDictionary {
            if let versionNumber = infoDictionary["CFBundleShortVersionString"] as? String {
                applicationVersion = versionNumber
            }
            if let buildNumber = infoDictionary["CFBundleVersion"] as? String {
                applicationBuildNumber = buildNumber
            }
        }
        return "app v\(applicationVersion) (\(applicationBuildNumber))"
    }

    func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let model = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                return identifier
            }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return model
    }

    func systemVersion() -> String {
        let systemName = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion
        return "\(systemName) v\(systemVersion)"
    }

    func canBeVisible() -> Bool {
        if let window = UIApplication.shared.keyWindow, window.isKeyWindow, !window.isHidden {
            return true
        }
        return false
    }
}

// MARK: Class Methods

private extension PerformanceView {
    class func windowFrame(withPrefferedHeight height: CGFloat) -> CGRect {
        guard let window = UIApplication.shared.delegate?.window as? UIWindow else {
            return .zero
        }

        var topInset: CGFloat = 0.0
        if #available(iOS 11.0, *), let safeAreaTop = window.rootViewController?.view.safeAreaInsets.top {
            if safeAreaTop > 0.0 {
                if safeAreaTop > Constants.defaultStatusBarHeight {
                    topInset = safeAreaTop - Constants.safeAreaInsetDifference
                } else {
                    topInset = safeAreaTop - Constants.defaultStatusBarHeight
                }
            } else {
                topInset = safeAreaTop
            }
        }
        return CGRect(x: 0.0, y: topInset, width: window.bounds.width, height: height)
    }
}
