import AppKit
import ScreenSaver

private struct TrendsPayload: Decodable {
    let fetchedAt: Date
    let region: String
    let trends: [Trend]

    private enum CodingKeys: String, CodingKey {
        case fetchedAt = "fetched_at"
        case region
        case trends
    }
}

private struct Trend: Decodable {
    let title: String
    let link: String?
    let traffic: String?
    let picture: String?
    let headline: String?
    let source: String?
    let url: String?
}

@objc(TrendsView)
public class TrendsView: ScreenSaverView {
    private let rootLayer = CALayer()
    private let backgroundLayer = CAGradientLayer()
    private let causticsLayer = CALayer()
    private let focusLayer = CALayer()
    private let cardLayer = CALayer()
    private let thumbLayer = CALayer()
    private let heroLayer = CATextLayer()
    private let headlineLayer = CATextLayer()
    private let sourceLayer = CATextLayer()
    private let trafficLayer = CATextLayer()
    private var footerLayer = CATextLayer()
    private var ghostLayers: [CATextLayer] = []
    private var trends: [Trend] = []
    private var payload: TrendsPayload?
    private var trendIndex = 0
    private var focusCenterRatio = CGPoint(x: 0.5, y: 0.5)
    private var cycleWorkItem: DispatchWorkItem?

    private static let trendsURL = URL(
        string: "https://apoorvkulkarni.com/trending-screensaver/trends.json"
    )!

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 30.0
        setupLayers()
        loadBundledTrends()
        refreshTrends()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 30.0
        setupLayers()
        loadBundledTrends()
        refreshTrends()
    }

    deinit {
        cycleWorkItem?.cancel()
    }

    private func setupLayers() {
        wantsLayer = true
        layer = rootLayer
        rootLayer.backgroundColor = NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.07, alpha: 1).cgColor
        rootLayer.masksToBounds = true

        backgroundLayer.colors = [
            NSColor(calibratedRed: 0.04, green: 0.13, blue: 0.25, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.03, green: 0.08, blue: 0.15, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.01, green: 0.03, blue: 0.06, alpha: 1).cgColor,
        ]
        backgroundLayer.locations = [0, 0.48, 1]
        rootLayer.addSublayer(backgroundLayer)

        rootLayer.addSublayer(causticsLayer)
        causticsLayer.opacity = 0.82
        addCausticRing(size: 0.72, x: 0.04, y: -0.24, opacity: 0.12, duration: 18)
        addCausticRing(size: 0.54, x: 0.58, y: 0.06, opacity: 0.09, duration: 23)
        addCausticRing(size: 0.42, x: 0.18, y: 0.28, opacity: 0.055, duration: 31)

        addGhostLayers(range: 0..<7, inFront: false)

        focusLayer.opacity = 0
        rootLayer.addSublayer(focusLayer)

        heroLayer.alignmentMode = .center
        heroLayer.truncationMode = .end
        focusLayer.addSublayer(heroLayer)

        cardLayer.backgroundColor = NSColor(calibratedRed: 0.02, green: 0.08, blue: 0.14, alpha: 0.7).cgColor
        cardLayer.borderColor = NSColor(calibratedRed: 0.35, green: 0.75, blue: 1, alpha: 0.18).cgColor
        cardLayer.borderWidth = 1
        cardLayer.cornerRadius = 14
        cardLayer.opacity = 0
        focusLayer.addSublayer(cardLayer)

        thumbLayer.backgroundColor = NSColor(calibratedRed: 0.07, green: 0.18, blue: 0.28, alpha: 1).cgColor
        thumbLayer.cornerRadius = 10
        thumbLayer.masksToBounds = true
        cardLayer.addSublayer(thumbLayer)
        cardLayer.addSublayer(headlineLayer)
        cardLayer.addSublayer(sourceLayer)
        cardLayer.addSublayer(trafficLayer)

        addGhostLayers(range: 7..<10, inFront: true)

        footerLayer = makeTextLayer(size: 15, color: NSColor(calibratedRed: 0.62, green: 0.82, blue: 0.94, alpha: 0.48))
        footerLayer.alignmentMode = .left
        rootLayer.addSublayer(footerLayer)
    }

    private func addGhostLayers(range: Range<Int>, inFront: Bool) {
        for index in range {
            let depth = inFront ? CGFloat.random(in: 0.72...0.9) : CGFloat.random(in: 0.15...0.68)
            let opacity = inFront ? Float.random(in: 0.32...0.45) : Float(0.24 + depth * 0.34)
            let fontSize = CGFloat(34 + depth * 78)
            let blur = inFront ? CGFloat.random(in: 0.05...0.35) : CGFloat(1.8 - depth * 1.2)
            let ghost = makeTextLayer(size: fontSize, color: NSColor(calibratedRed: 0.5, green: 0.88, blue: 1, alpha: 1))
            ghost.alignmentMode = .left
            ghost.opacity = 0
            ghost.filters = [CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": max(0.15, blur)]) as Any]
            ghost.setValue(depth, forKey: "depth")
            ghost.setValue(inFront, forKey: "inFront")
            ghost.setValue(opacity, forKey: "baseOpacity")
            ghost.setValue(CGFloat.random(in: 0.08...0.88), forKey: "trackY")
            ghost.setValue(Bool.random(), forKey: "startsRight")
            ghost.setValue(index, forKey: "ghostIndex")
            ghostLayers.append(ghost)
            rootLayer.addSublayer(ghost)
        }
    }

    private func addCausticRing(size: CGFloat, x: CGFloat, y: CGFloat, opacity: Float, duration: CFTimeInterval) {
        let group = CALayer()
        group.opacity = opacity
        group.setValue(size, forKey: "relativeSize")
        group.setValue(x, forKey: "relativeX")
        group.setValue(y, forKey: "relativeY")
        causticsLayer.addSublayer(group)

        for index in 0..<4 {
            let ring = CAShapeLayer()
            ring.fillColor = NSColor.clear.cgColor
            ring.strokeColor = NSColor(calibratedRed: 0.45, green: 0.84, blue: 1, alpha: CGFloat(0.42 - Double(index) * 0.065)).cgColor
            ring.lineWidth = CGFloat(1.4 + Double(index) * 0.8)
            ring.lineCap = .round
            ring.shadowColor = NSColor(calibratedRed: 0.4, green: 0.78, blue: 1, alpha: 0.45).cgColor
            ring.shadowOpacity = 0.6
            ring.shadowRadius = 8
            ring.shadowOffset = .zero
            ring.setValue(index, forKey: "ringIndex")
            group.addSublayer(ring)
        }

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.94
        scale.toValue = 1.08
        scale.duration = duration
        scale.autoreverses = true
        scale.repeatCount = .infinity
        scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        group.add(scale, forKey: "breath")

        let sway = CABasicAnimation(keyPath: "transform.translation.x")
        sway.fromValue = -18
        sway.toValue = 26
        sway.duration = duration * 0.72
        sway.autoreverses = true
        sway.repeatCount = .infinity
        sway.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        group.add(sway, forKey: "sway")
    }

    private func makeTextLayer(size: CGFloat, color: NSColor) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        textLayer.foregroundColor = color.cgColor
        textLayer.font = "SF Pro Rounded" as CFTypeRef
        textLayer.fontSize = size
        textLayer.isWrapped = true
        return textLayer
    }

    public override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let b = bounds
        rootLayer.frame = b
        backgroundLayer.frame = b
        causticsLayer.frame = b
        for group in causticsLayer.sublayers ?? [] {
            let relativeSize = group.value(forKey: "relativeSize") as? CGFloat ?? 0.6
            let relativeX = group.value(forKey: "relativeX") as? CGFloat ?? 0
            let relativeY = group.value(forKey: "relativeY") as? CGFloat ?? 0
            let side = max(b.width, b.height) * relativeSize
            group.frame = CGRect(x: b.width * relativeX, y: b.height * relativeY, width: side, height: side)
            for ring in group.sublayers ?? [] {
                let ringIndex = ring.value(forKey: "ringIndex") as? Int ?? 0
                let inset = side * CGFloat(0.08 + Double(ringIndex) * 0.105)
                let heightSquash = side * CGFloat(0.1 + Double(ringIndex) * 0.04)
                ring.frame = group.bounds
                (ring as? CAShapeLayer)?.path = CGPath(
                    ellipseIn: group.bounds.insetBy(dx: inset, dy: inset + heightSquash),
                    transform: nil
                )
            }
        }

        footerLayer.frame = CGRect(x: 28, y: 24, width: b.width - 56, height: 24)
        layoutFocus()
        CATransaction.commit()
    }

    private func layoutFocus() {
        let b = bounds
        focusLayer.frame = b
        let focusCenter = CGPoint(x: b.width * focusCenterRatio.x, y: b.height * focusCenterRatio.y)
        let heroWidth = b.width * 0.9
        let cardWidth = min(b.width * 0.72, 880)
        let heroHeight: CGFloat = 112
        let cardHeight: CGFloat = 150
        let gap: CGFloat = 12
        let groupHeight = heroHeight + gap + cardHeight
        let groupY = min(max(focusCenter.y - groupHeight / 2, b.height * 0.18), b.height * 0.82 - groupHeight)
        heroLayer.frame = CGRect(x: b.width * 0.05, y: groupY + cardHeight + gap, width: heroWidth, height: heroHeight)
        cardLayer.frame = CGRect(x: focusCenter.x - cardWidth / 2, y: groupY, width: cardWidth, height: cardHeight)
        thumbLayer.frame = CGRect(x: 18, y: 24, width: 102, height: 102)
        headlineLayer.frame = CGRect(x: 140, y: 76, width: cardLayer.bounds.width - 164, height: 52)
        sourceLayer.frame = CGRect(x: 140, y: 48, width: cardLayer.bounds.width - 164, height: 22)
        trafficLayer.frame = CGRect(x: 140, y: 22, width: cardLayer.bounds.width - 164, height: 22)

        for ghost in ghostLayers {
            layoutGhost(ghost)
        }
    }

    private func layoutGhost(_ ghost: CATextLayer) {
        let b = bounds
        let depth = ghost.value(forKey: "depth") as? CGFloat ?? 0.5
        let trackY = ghost.value(forKey: "trackY") as? CGFloat ?? 0.5
        let fontSize = CGFloat(34 + depth * 78)
        ghost.fontSize = fontSize
        ghost.frame = CGRect(
            x: -b.width * 0.45,
            y: b.height * trackY,
            width: b.width * 1.9,
            height: fontSize * 1.45
        )
    }

    private func loadBundledTrends() {
        let bundle = Bundle(for: TrendsView.self)
        guard let url = bundle.url(forResource: "trends", withExtension: "json", subdirectory: "web"),
              let data = try? Data(contentsOf: url) else {
            showMessage("trends unavailable")
            return
        }
        applyTrendsData(data)
    }

    private func refreshTrends() {
        URLSession.shared.dataTask(with: Self.trendsURL) { [weak self] data, _, _ in
            guard let data else { return }
            DispatchQueue.main.async {
                self?.applyTrendsData(data)
            }
        }.resume()
    }

    private func applyTrendsData(_ data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = Self.fractionalISO8601.date(from: value) ?? Self.iso8601.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date: \(value)"
            )
        }
        guard let payload = try? decoder.decode(TrendsPayload.self, from: data),
              !payload.trends.isEmpty else {
            showMessage("trends unavailable")
            return
        }
        self.payload = payload
        trends = payload.trends
        trendIndex = 0
        footerLayer.string = "Google Trends - \(payload.region) - \(formattedDate(payload.fetchedAt))"
        for (index, ghost) in ghostLayers.enumerated() {
            ghost.string = randomTrendTitle(excluding: nil)
            randomizeGhost(ghost)
            animateGhost(ghost, index: index)
        }
        scheduleNextTrend(after: 0)
    }

    private func randomTrendTitle(excluding excluded: String?) -> String {
        let candidates = trends
            .map { $0.title.lowercased() }
            .filter { $0 != excluded?.lowercased() }
        return (candidates.randomElement() ?? trends.first?.title.lowercased()) ?? ""
    }

    private func randomizeGhost(_ ghost: CATextLayer) {
        ghost.setValue(CGFloat.random(in: 0.08...0.88), forKey: "trackY")
        ghost.setValue(Bool.random(), forKey: "startsRight")
        layoutGhost(ghost)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private static let fractionalISO8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601 = ISO8601DateFormatter()

    private func showMessage(_ message: String) {
        heroLayer.string = message
        heroLayer.fontSize = 76
        focusLayer.opacity = 1
        cardLayer.opacity = 0
    }

    private func scheduleNextTrend(after delay: TimeInterval) {
        cycleWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.showNextTrend() }
        cycleWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func showNextTrend() {
        guard !trends.isEmpty else { return }
        let trend = trends.randomElement() ?? trends[trendIndex % trends.count]
        trendIndex += 1
        render(trend)
        refreshGhostTitles(avoiding: trend.title)
        animateFocus()
        scheduleNextTrend(after: 12)
    }

    private func refreshGhostTitles(avoiding heroTitle: String) {
        for (index, ghost) in ghostLayers.enumerated() {
            if ghost.string == nil {
                ghost.string = randomTrendTitle(excluding: heroTitle)
                randomizeGhost(ghost)
                animateGhost(ghost, index: index)
            }
        }
    }

    private func render(_ trend: Trend) {
        heroLayer.string = trend.title.lowercased()
        heroLayer.fontSize = trend.title.count > 35 ? 54 : trend.title.count > 20 ? 72 : 96
        heroLayer.foregroundColor = NSColor(calibratedRed: 0.91, green: 0.97, blue: 1, alpha: 1).cgColor

        headlineLayer.string = trend.headline ?? ""
        headlineLayer.fontSize = 24
        headlineLayer.foregroundColor = NSColor(calibratedRed: 0.82, green: 0.94, blue: 1, alpha: 0.86).cgColor
        sourceLayer.string = trend.source ?? ""
        sourceLayer.fontSize = 16
        sourceLayer.foregroundColor = NSColor(calibratedRed: 0.65, green: 0.84, blue: 0.94, alpha: 0.58).cgColor
        trafficLayer.string = trend.traffic.map { "\($0) searches" } ?? ""
        trafficLayer.fontSize = 15
        trafficLayer.foregroundColor = NSColor(calibratedRed: 0.65, green: 0.84, blue: 0.94, alpha: 0.45).cgColor

        thumbLayer.contents = nil
        thumbLayer.backgroundColor = NSColor(calibratedRed: 0.07, green: 0.18, blue: 0.28, alpha: 1).cgColor
        if let picture = trend.picture, let url = URL(string: picture) {
            loadImage(url)
        }
    }

    private func loadImage(_ url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.thumbLayer.contents = image
                self?.thumbLayer.contentsGravity = .resizeAspectFill
            }
        }.resume()
    }

    private func animateFocus() {
        focusLayer.removeAllAnimations()
        cardLayer.removeAllAnimations()
        focusLayer.opacity = 0
        cardLayer.opacity = 0
        focusLayer.transform = CATransform3DIdentity
        focusCenterRatio = CGPoint(x: CGFloat.random(in: 0.32...0.68), y: CGFloat.random(in: 0.42...0.66))
        layoutFocus()

        let begin = CACurrentMediaTime()
        let entrySide = Int.random(in: 0..<4)
        var exitSide = Int.random(in: 0..<4)
        if exitSide == entrySide {
            exitSide = (exitSide + Int.random(in: 1...3)) % 4
        }
        let entry = edgeTransform(for: entrySide)
        let exit = edgeTransform(for: exitSide)

        let opacity = CAKeyframeAnimation(keyPath: "opacity")
        opacity.values = [0, 1, 1, 1, 0]
        opacity.keyTimes = [0, 0.16, 0.52, 0.84, 1]
        opacity.duration = 11.8
        opacity.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeIn),
        ]
        opacity.beginTime = begin
        opacity.fillMode = .forwards
        opacity.isRemovedOnCompletion = false
        focusLayer.add(opacity, forKey: "focusOpacity")

        let transform = CAKeyframeAnimation(keyPath: "transform")
        transform.values = [
            CATransform3DConcat(entry, CATransform3DMakeScale(0.72, 0.72, 1)),
            CATransform3DMakeScale(1.0, 1.0, 1),
            CATransform3DMakeScale(1.0, 1.0, 1),
            CATransform3DConcat(exit, CATransform3DMakeScale(0.76, 0.76, 1)),
        ]
        transform.keyTimes = [0, 0.18, 0.72, 1]
        transform.duration = 11.8
        transform.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeInEaseOut),
        ]
        transform.beginTime = begin
        transform.fillMode = .forwards
        transform.isRemovedOnCompletion = false
        focusLayer.add(transform, forKey: "focusDepth")

        let causticPulse = CABasicAnimation(keyPath: "opacity")
        causticPulse.fromValue = 0.82
        causticPulse.toValue = 1
        causticPulse.duration = 1.2
        causticPulse.autoreverses = true
        causticPulse.timingFunction = CAMediaTimingFunction(name: .easeOut)
        causticsLayer.add(causticPulse, forKey: "pulse")

        let cardFade = CABasicAnimation(keyPath: "opacity")
        cardFade.fromValue = 0
        cardFade.toValue = 1
        cardFade.beginTime = begin + 4.2
        cardFade.duration = 0.9
        cardFade.fillMode = .forwards
        cardFade.isRemovedOnCompletion = false
        cardLayer.add(cardFade, forKey: "cardIn")
    }

    private func edgeTransform(for direction: Int) -> CATransform3D {
        let b = bounds
        let focusCenter = CGPoint(x: b.width * focusCenterRatio.x, y: b.height * focusCenterRatio.y)
        let horizontalOvershoot = b.width * 0.55 + focusCenter.x
        let rightOvershoot = b.width * 1.55 - focusCenter.x
        let bottomOvershoot = b.height * 0.55 + focusCenter.y
        let topOvershoot = b.height * 1.55 - focusCenter.y
        switch direction {
        case 0:
            return CATransform3DMakeTranslation(-horizontalOvershoot, CGFloat.random(in: -b.height * 0.12...b.height * 0.12), 0)
        case 1:
            return CATransform3DMakeTranslation(rightOvershoot, CGFloat.random(in: -b.height * 0.12...b.height * 0.12), 0)
        case 2:
            return CATransform3DMakeTranslation(CGFloat.random(in: -b.width * 0.16...b.width * 0.16), topOvershoot, 0)
        default:
            return CATransform3DMakeTranslation(CGFloat.random(in: -b.width * 0.16...b.width * 0.16), -bottomOvershoot, 0)
        }
    }

    private func animateGhost(_ ghost: CATextLayer, index: Int) {
        ghost.removeAnimation(forKey: "swim")
        let width = bounds.width
        let height = bounds.height
        let depth = ghost.value(forKey: "depth") as? CGFloat ?? 0.5
        let baseOpacity = ghost.value(forKey: "baseOpacity") as? Float ?? 0.12
        let startsRight = ghost.value(forKey: "startsRight") as? Bool ?? false
        let startX = startsRight ? width * 1.18 : -width * 0.58
        let endX = startsRight ? -width * 0.82 : width * 1.22
        let wave = height * CGFloat(0.012 + depth * 0.04)
        let duration = CFTimeInterval(62 - depth * 28 + CGFloat.random(in: -4...6))

        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.values = [
            CATransform3DMakeTranslation(startX, 0, 0),
            CATransform3DMakeTranslation(startX + (endX - startX) * 0.08, wave * 0.55, 0),
            CATransform3DMakeTranslation(startX + (endX - startX) * 0.25, -wave, 0),
            CATransform3DMakeTranslation(startX + (endX - startX) * 0.5, 0, 0),
            CATransform3DMakeTranslation(startX + (endX - startX) * 0.75, wave, 0),
            CATransform3DMakeTranslation(startX + (endX - startX) * 0.92, -wave * 0.45, 0),
            CATransform3DMakeTranslation(endX, 0, 0),
        ]
        animation.keyTimes = [0, 0.08, 0.25, 0.5, 0.75, 0.92, 1]
        animation.timingFunction = CAMediaTimingFunction(name: .linear)

        let opacity = CAKeyframeAnimation(keyPath: "opacity")
        opacity.values = [0, 0, baseOpacity, baseOpacity, 0, 0]
        opacity.keyTimes = [0, 0.06, 0.14, 0.86, 0.96, 1]
        opacity.timingFunctions = [
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeIn),
            CAMediaTimingFunction(name: .linear),
        ]

        let group = CAAnimationGroup()
        group.animations = [animation, opacity]
        group.duration = duration
        group.beginTime = CACurrentMediaTime() + CFTimeInterval.random(in: 0...duration)
        group.repeatCount = .infinity
        group.fillMode = .backwards
        group.isRemovedOnCompletion = false
        ghost.add(group, forKey: "swim")
    }

    public override func animateOneFrame() {
        // Core Animation owns the motion.
    }

    public override var hasConfigureSheet: Bool { false }
    public override var configureSheet: NSWindow? { nil }
}
