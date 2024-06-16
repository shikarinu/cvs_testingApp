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
]

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

// RowView 構造体の定義
struct RowView: View {
    var photo: PhotoData
    
    var body: some View {
        HStack {
            Image(photo.imageName)
                .resizable()
                .frame(width: 60, height: 60)
                .cornerRadius(30) // 画像を丸くするための設定
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
                NavigationLink(destination: SongListView(artist: photo.artist)) { // クリックでSongListViewへ遷移
                    RowView(photo: photo)
                }
            }
            .navigationBarTitleDisplayMode(.inline) // ナビゲーションタイトルをインラインに設定
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(photoArray[0].imageName) // ここでは1つの画像を使用しますが、実際には必要に応じて変更します
                            .resizable()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                        Text("アーティスト")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// SongListView 構造体の定義
struct SongListView: View {
    var artist: String // アーティスト名を受け取るプロパティ
    
    var body: some View {
        VStack {
            HStack {
                Image(artist.lowercased() + "_img") // アーティスト画像を表示
                    .resizable()
                    .frame(width: 60, height: 60)
                    .cornerRadius(50) // 画像を丸くするための設定
                Text(artist) // アーティスト名を画像の横に表示
                    .font(.largeTitle)
                    .padding(.leading, 10)
            }
            .padding()
            
            // アーティストの曲リストを表示
            if let songs = artistSongs[artist] {
                List(songs.keys.sorted(), id: \.self) { song in
                    if let url = songs[song] {
                        NavigationLink(destination: SongDetailView(artist: artist, song: song, url: url)) { // クリックでSongDetailViewへ遷移
                            HStack {
                                Image(artist.lowercased() + "_img")
                                    .resizable()
                                    .frame(width: 60, height: 60)
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
                .edgesIgnoringSafeArea(.top) // 上部のセーフエリアを無視
                .frame(height: 300) // 動画プレイヤーの高さ
                .cornerRadius(10)
            
            HStack {
                Image(artist.lowercased() + "_img") // アーティストアイコンを表示
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(20)
                    .padding(.trailing, 10)
                Text(song) // 曲名をアイコンの横に表示
                    .font(.largeTitle)
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
        webView.navigationDelegate = context.coordinator // navigationDelegateを設定
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
            if (error as NSError).code == 102 { // 埋め込みが拒否された場合のエラーコード
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

struct RowView_Previews: PreviewProvider {
    static var previews: some View {
        RowView(photo: photoArray[0])
    }
}
