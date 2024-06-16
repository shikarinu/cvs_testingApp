import SwiftUI
import WebKit

// PhotoData 構造体の定義
struct PhotoData: Identifiable {
    var id = UUID()
    var imageName: String
    var artist: String
}

// データの定義
let photoArray = [
    PhotoData(imageName: "aespa_img", artist: "aespa"),
    PhotoData(imageName: "bigbang_img", artist: "BIGBANG"),
    PhotoData(imageName: "itzy_img", artist: "ITZY"),
    PhotoData(imageName: "ive_img", artist: "IVE"),
    PhotoData(imageName: "stray_kids_img", artist: "Stray_Kids"),
].sorted { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }

// アーティストごとの曲データとYouTube URLを格納する辞書
var artistSongs: [String: [String: String]] = [:]

// CSVファイルを読み込んで辞書に格納する関数
func loadCSV() {
    guard let path = Bundle.main.path(forResource: "songs", ofType: "csv") else {
        print("CSV file not found")
        return
    }
    
    do {
        let content = try String(contentsOfFile: path)
        let lines = content.split(separator: "\n")
        
        for line in lines.dropFirst() { // dropFirst()でヘッダー行をスキップ
            let columns = line.split(separator: ",").map { String($0) }
            if columns.count == 3 {
                let artist = columns[0]
                let song = columns[1]
                let url = columns[2]
                
                if !artist.isEmpty && !song.isEmpty && !url.isEmpty {
                    if artistSongs[artist] == nil {
                        artistSongs[artist] = [:]
                    }
                    artistSongs[artist]?[song] = url
                }
            }
        }
    } catch {
        print("Error reading CSV file: \(error)")
    }
}

// 共通の画像表示と丸くする処理
struct RoundImage: View {
    var imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .frame(width: 60, height: 60)
            .cornerRadius(30)
    }
}

// RowView 構造体の定義
struct RowView: View {
    var photo: PhotoData
    
    var body: some View {
        HStack {
            RoundImage(imageName: photo.imageName)
                .padding(.trailing, 10)
            Text(photo.artist)
                .font(.title)
                .padding()
        }
    }
}

// ContentView 構造体の定義
struct ContentView: View {
    init() {
        loadCSV() // CSVファイルを読み込む
    }
    
    var body: some View {
        NavigationView {
            List(photoArray) { photo in
                NavigationLink(destination: SongListView(artist: photo.artist)) {
                    RowView(photo: photo)
                }
            }
            .navigationBarTitle("アーティスト一覧")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// SongListView 構造体の定義
struct SongListView: View {
    var artist: String
    
    var body: some View {
        VStack {
            HStack {
                RoundImage(imageName: artist.lowercased() + "_img")
                    .cornerRadius(50)
                    .frame(width: 60, height: 60)
                Text(artist)
                    .font(.largeTitle)
                    .padding(.leading, 10)
            }
            .padding()
            
            // アーティストの曲リストを表示
            if let songs = artistSongs[artist] {
                List(songs.keys.sorted(), id: \.self) { song in
                    if let url = songs[song] {
                        NavigationLink(destination: SongDetailView(artist: artist, song: song, url: url)) {
                            HStack {
                                RoundImage(imageName: artist.lowercased() + "_img")
                                    .cornerRadius(20)
                                    .padding(.trailing, 10)
                                Text(song)
                                    .font(.title)
                            }
                        }
                    } else {
                        Text("URLが見つかりません")
                    }
                }
            } else {
                Text("曲が見つかりません")
            }
        }
        .navigationTitle(artist)
    }
}

// SongDetailView 構造体の定義
struct SongDetailView: View {
    var artist: String
    var song: String
    var url: String
    
    var body: some View {
        VStack {
            // YouTube動画の埋め込み
            WebView(urlString: url)
                .edgesIgnoringSafeArea(.top)
                .frame(height: 300)
                .cornerRadius(10)
            
            HStack {
                RoundImage(imageName: artist.lowercased() + "_img")
                    .cornerRadius(20)
                    .frame(width: 80, height: 80)
                    .padding(.trailing, 10)
                Text(song)
                    .font(.title)
            }
            .padding()
            
            Spacer()
        }
    }
}

// WebView 構造体の定義
struct WebView: UIViewRepresentable {
    var urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code == 102 {
                webView.loadHTMLString("<html><body><h1>この動画は埋め込みできません。</h1><p>YouTubeアプリでご覧ください。</p><a href='\(parent.urlString)'>YouTubeで開く</a></body></html>", baseURL: nil)
            }
        }
    }
}

// プレビュー用の構造体
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
