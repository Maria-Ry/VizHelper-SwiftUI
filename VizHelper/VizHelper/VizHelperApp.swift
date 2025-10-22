
import SwiftUI

@main
struct VizHelperApp: App {
    @StateObject var api = APIClient()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(api)
        }
    }
}
