import SwiftUI
import UserNotifications
import WebKit

// Adăugăm clasa NotificationManager
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Permisiuni pentru notificări acordate!")
            } else if let error = error {
                print("Eroare: \(error.localizedDescription)")
            }
        }
    }
    
    func schedulePushNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Aplicația 1"
        content.body = "Bine ați venit! Mulțumim că folosiți aplicația."
        content.sound = UNNotificationSound.default
        
        // Notificare după 10 secunde
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        
        let request = UNNotificationRequest(identifier: "welcomeNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Eroare la programarea notificării: \(error)")
            } else {
                print("Notificarea a fost programată cu succes!")
            }
        }
    }
    
    // Această metodă permite afișarea notificării și când aplicația e deschisă
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

struct ContentView: View {
    @State private var searchText: String = ""
    @State private var items: [String] = []
    @State private var showWebView = false
    @State private var selectedURL: URL? = nil
    
    // State pentru dialogurile de confirmare
    @State private var showClearConfirmation = false
    @State private var showDuplicateConfirmation = false
    @State private var duplicateItem = ""
    
    // Inițializăm managerul de notificări
    private let notificationManager = NotificationManager.shared
    
    var body: some View {
        VStack {
            TextField("Introdu un element", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .disableAutocorrection(true)
                .autocapitalization(.none)
            
            HStack {
                Button("Adaugă Element") { addItem() }
                    .buttonStyle(.bordered)
                
                Button("Șterge Tot") {
                    // Arată dialogul de confirmare în loc de a șterge direct
                    showClearConfirmation = true
                }
                .buttonStyle(.bordered)
            }
            
            List {
                ForEach(items, id: \.self) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item)
                            Text("https://www.google.com/search?q=\(item.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        Button("Caută") {
                            searchOnGoogle(item)
                        }
                        .buttonStyle(.bordered)
                        Button("Șterge") { removeItem(item) }
                            .buttonStyle(.bordered)
                    }
                }
            }
            
            if let url = selectedURL {
                VStack {
                    Text("Căutare Google: \(url.absoluteString)")
                        .font(.footnote)
                        .padding()
                    WebView(url: url)
                        .frame(height: 300)
                }
            }
        }
        .padding()
        .onAppear {
            // Inițializăm și cerem permisiuni pentru notificări
            notificationManager.requestPermissions()
            
            // Programăm notificarea pentru peste 10 secunde
            notificationManager.schedulePushNotification()
        }
        // Dialog de confirmare pentru ștergerea tuturor elementelor
        .alert("Confirmare ștergere", isPresented: $showClearConfirmation) {
            Button("Da, șterge tot", role: .destructive) {
                clearAllItems()
            }
            Button("Anulează", role: .cancel) { }
        } message: {
            Text("Sigur doriți să ștergeți toate elementele?")
        }
        // Dialog de confirmare pentru elementele duplicate
        .alert("Element duplicat", isPresented: $showDuplicateConfirmation) {
            Button("Adaugă oricum") {
                items.append(duplicateItem)
                searchText = ""
            }
            Button("Anulează", role: .cancel) {
                searchText = ""
            }
        } message: {
            Text("Elementul '\(duplicateItem)' există deja. Doriți să îl adăugați din nou?")
        }
    }
    
    private func addItem() {
        guard !searchText.isEmpty else { return }
        
        if items.contains(searchText) {
            // În loc de a trimite doar o notificare, arătăm dialogul de confirmare
            duplicateItem = searchText
            showDuplicateConfirmation = true
        } else {
            items.append(searchText)
            searchText = ""
        }
    }
    
    private func clearAllItems() {
        items.removeAll()
        sendNotification(message: "Toate elementele au fost șterse!")
    }
    
    private func removeItem(_ item: String) {
        items.removeAll { $0 == item }
    }
    
    private func searchOnGoogle(_ query: String) {
        if let url = URL(string: "https://www.google.com/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            selectedURL = url
            showWebView.toggle()
        }
    }
    
    // Păstrăm și funcția inițială pentru notificări simple
    private func sendNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Notificare"
        content.body = message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
