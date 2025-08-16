import SwiftUI

struct SettingsView: View {
    // Use AppStorage to persist the user's color scheme choice
    @AppStorage("colorScheme") private var colorScheme: String = "system"

    var body: some View {
        Form {
            Section(header: Text("表示設定")) {
                Picker("モード", selection: $colorScheme) {
                    Text("システム設定").tag("system")
                    Text("ライト").tag("light")
                    Text("ダーク").tag("dark")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle("設定")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
