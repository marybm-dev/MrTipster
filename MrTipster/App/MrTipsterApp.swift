import SwiftUI

@main
struct MrTipsterApp: App {
    @State private var model: TipperModel
    private let autoFocus: Bool

    init() {
        let launch = LaunchOptions()
        launch.prepare()
        _model = State(initialValue: TipperModel(settings: AppSettings()))
        autoFocus = launch.autoFocus
        launch.apply(to: model)
    }

    var body: some Scene {
        WindowGroup {
            CalculatorView(model: model, autoFocus: autoFocus)
        }
    }
}

/// Launch arguments used by UI tests, screenshots and VoiceOver checks, e.g.
/// `-resetState YES -demoBill 86.40 -demoTip 20 -demoPeople 3 -autoFocus NO`.
/// Debug builds only.
private struct LaunchOptions {
    #if DEBUG
    private let defaults = UserDefaults.standard
    var autoFocus: Bool { defaults.object(forKey: "autoFocus") as? Bool ?? true }

    func prepare() {
        if defaults.bool(forKey: "resetState"), let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        }
    }

    @MainActor
    func apply(to model: TipperModel) {
        if let bill = defaults.string(forKey: "demoBill") {
            model.billText = BillInput.convert(bill, from: ".", to: model.money.decimalSeparator)
            model.billTextDidChange()
        }
        if defaults.object(forKey: "demoTip") != nil { model.setTip(defaults.integer(forKey: "demoTip")) }
        if defaults.object(forKey: "demoPeople") != nil { model.setPeople(defaults.integer(forKey: "demoPeople")) }
    }
    #else
    var autoFocus: Bool { true }
    func prepare() {}
    @MainActor func apply(to model: TipperModel) {}
    #endif
}
