import SwiftUI

@main
struct TestFrameworkApp: App {

    @StateObject private var model =
        ConversionModel(rateProvider: SampleRateProvider())

    var body: some Scene {
        WindowGroup {
            ConversionView(model: model)
        }
    }
}
