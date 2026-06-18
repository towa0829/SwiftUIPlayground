# 02 SettingsApp ロードマップ

完成形: AppStorage で永続化される設定画面（テーマ・通知・アカウント）

---

## Step 1 — 選択肢の enum を作る
**ファイル:** `Models/AppTheme.swift` を新規作成

### 1-1: AppTheme enum の骨格
```swift
import Foundation

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "システム"
    case light  = "ライト"
    case dark   = "ダーク"

    var id: String { rawValue }
}
```
▶ ここで確認: `AppTheme.allCases` をプリントして3件出ること

### 1-2: FontSize と Language を追加
```swift
enum FontSize: String, CaseIterable, Identifiable {
    case small  = "小"
    case medium = "中"
    case large  = "大"

    var id: String { rawValue }
}

enum Language: String, CaseIterable, Identifiable {
    case japanese = "日本語"
    case english  = "English"

    var id: String { rawValue }
}
```

---

## Step 2 — Form の骨格を作る
**ファイル:** `Views/SettingsView.swift` を新規作成

### 2-1: NavigationStack + Form の最小構成
```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("外観") {
                    Text("ここに設定項目を追加")
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview { SettingsView() }
```
▶ ここで確認: Preview で「設定」タイトルとセクションが出ること

### 2-2: 全セクションの見出しだけ先に並べる
```swift
            Form {
                Section("アカウント") { Text("...") }
                Section("外観") { Text("...") }
                Section("通知") { Text("...") }
                Section("セキュリティ") { Text("...") }
                Section("アプリ情報") { Text("...") }
            }
```
▶ ここで確認: Preview で5つのセクションが見えること

---

## Step 3 — SettingsViewModel で設定値を永続化する
**ファイル:** `ViewModels/SettingsViewModel.swift` を新規作成

MVVMでは View に `@AppStorage` を直接置かず、ViewModel に状態を集約して
`UserDefaults` への読み書きを `didSet` で行う。

### 3-1: ViewModel の骨格（テーマ・フォントサイズのみ）
```swift
import Foundation

class SettingsViewModel: ObservableObject {
    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Key.theme) }
    }
    @Published var fontSize: FontSize {
        didSet { defaults.set(fontSize.rawValue, forKey: Key.fontSize) }
    }

    private let defaults: UserDefaults

    private enum Key {
        static let theme = "app_theme"
        static let fontSize = "font_size"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        theme = AppTheme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .system
        fontSize = FontSize(rawValue: defaults.string(forKey: Key.fontSize) ?? "") ?? .medium
    }
}
```
▶ ここで確認: ビルドエラーがないこと

### 3-2: SettingsView から ViewModel を生成して表示するだけのテキストを置く
```swift
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("現在の値（確認用）") {
                    Text("テーマ: \(viewModel.theme.rawValue)")
                    Text("フォント: \(viewModel.fontSize.rawValue)")
                }
            }
            .navigationTitle("設定")
        }
    }
}
```
▶ ここで確認: アプリ終了・再起動後も値が保持されること（シミュレーターで確認）

### 3-3: 通知・サウンド・ハプティクス・自動ロック・ユーザー名を ViewModel に追加
```swift
    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Key.notificationsEnabled) }
    }
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Key.soundEnabled) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.hapticsEnabled) }
    }
    @Published var autoLock: Bool {
        didSet { defaults.set(autoLock, forKey: Key.autoLock) }
    }
    @Published var username: String {
        didSet { defaults.set(username, forKey: Key.username) }
    }
```
（対応する `Key` と `init` の読み込み・デフォルト値も追加する）

---

## Step 4 — Toggle を実装する
**ファイル:** `Views/SettingsView.swift` の「通知」セクションを編集

### 4-1: Toggle の基本形
```swift
                Section("通知") {
                    // isOn: に $binding を渡すことで Toggle が値を書き換える
                    Toggle("通知を受け取る", isOn: $viewModel.notificationsEnabled)
                }
```
▶ ここで確認: トグルをON/OFFするとStep 3の確認用テキストが切り替わること

### 4-2: if で関連項目を条件表示
```swift
                Section("通知") {
                    Toggle("通知を受け取る", isOn: $viewModel.notificationsEnabled)

                    // notificationsEnabled が true の時だけ表示される
                    if viewModel.notificationsEnabled {
                        Toggle("サウンド", isOn: $viewModel.soundEnabled)
                        Toggle("バイブレーション", isOn: $viewModel.hapticsEnabled)
                    }
                }
```
▶ ここで確認: 「通知」をOFFにすると「サウンド」「バイブレーション」が消えること

---

## Step 5 — Picker を実装する
**ファイル:** `Views/SettingsView.swift` の「外観」セクションを編集

### 5-1: Picker の基本形（enum を直接 selection に渡す）
```swift
                Section("外観") {
                    Picker("テーマ", selection: $viewModel.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }
```
▶ ここで確認: タップするとドロップダウンで選択肢が出ること

### 5-2: .pickerStyle を変えて違いを体感する
```swift
                    Picker("フォントサイズ", selection: $viewModel.fontSize) {
                        ForEach(FontSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    // .pickerStyle(.segmented) を試してみる
```

### 5-3: NavigationLink スタイルのピッカー（別画面で選択）
```swift
                    Picker("言語", selection: $viewModel.language) {
                        ForEach(Language.allCases) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    }
                    .pickerStyle(.navigationLink)
```
（`language: Language` も Step 3 と同様に ViewModel へ追加する）

▶ ここで確認: 「言語」だけ別画面でリスト選択になること

---

## Step 6 — アカウントセクションと残りを完成させる
**ファイル:** `Views/SettingsView.swift`

### 6-1: アカウントセクション（TextField + HStack）
```swift
                Section("アカウント") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            TextField("ユーザー名", text: $viewModel.username)
                                .font(.headline)
                            Text("プロフィールを編集")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
```

### 6-2: セキュリティセクション（Toggle + NavigationLink）
**ファイル:** `Views/PasswordPlaceholderView.swift` を新規作成して切り出す
```swift
struct PasswordPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("パスワード変更画面")
                .font(.headline)
        }
        .navigationTitle("パスワード変更")
    }
}

#Preview {
    NavigationStack { PasswordPlaceholderView() }
}
```
SettingsView 側ではこれを呼び出すだけにする:
```swift
                Section("セキュリティ") {
                    Toggle("自動ロック", isOn: $viewModel.autoLock)
                    NavigationLink("パスワードを変更") {
                        PasswordPlaceholderView()
                    }
                }
```

### 6-3: アプリ情報セクション（LabeledContent + Link + Button）
```swift
                Section("アプリ情報") {
                    LabeledContent("バージョン", value: "1.0.0")
                    LabeledContent("ビルド", value: "42")
                    Link("プライバシーポリシー", destination: URL(string: "https://example.com")!)
                    Button("設定をエクスポート") {
                        showExportAlert = true
                    }
                }
```
（`@State private var showExportAlert = false` と、内容を文字列で返す
`viewModel.exportSettings()` を使った `.alert` も追加する）

### 6-4: リセットボタン + Alert（ViewModel に処理を持たせる）
```swift
    func resetAllSettings() {
        theme = .system
        fontSize = .medium
        language = .japanese
        notificationsEnabled = true
        soundEnabled = true
        hapticsEnabled = true
        autoLock = false
        username = ""
    }
```
View 側:
```swift
    @State private var showResetAlert = false

                Section {
                    Button("すべての設定をリセット", role: .destructive) {
                        showResetAlert = true
                    }
                }
            }
            .alert("設定をリセット", isPresented: $showResetAlert) {
                Button("リセット", role: .destructive) {
                    // @Published への代入なのでUIへ即時反映される
                    viewModel.resetAllSettings()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("すべての設定がデフォルトに戻ります。")
            }
```
▶ ここで確認: リセット後に設定値がすぐにデフォルトへ戻ること（UserDefaultsを
直接 `removeObject` するだけでは画面に反映されない点に注意）

### 6-5: 見た目への反映（テーマ・フォントサイズ）
```swift
            .navigationTitle("設定")
            .preferredColorScheme(viewModel.theme.colorScheme)
            .dynamicTypeSize(viewModel.fontSize.dynamicTypeSize)
```
`AppTheme.colorScheme: ColorScheme?` と `FontSize.dynamicTypeSize: DynamicTypeSize`
を `Models/AppTheme.swift` に計算プロパティとして追加する。

▶ ここで確認: テーマを「ダーク」に切り替えると画面全体が即座に切り替わること

---

## 完成チェックリスト
- [ ] 5つのセクションが表示される
- [ ] Toggle のON/OFFが即反映される
- [ ] 通知OFFで子設定が非表示になる
- [ ] 3種類のPickerスタイルを確認した
- [ ] アプリ再起動後も設定値が保持される（SettingsViewModel経由のUserDefaults同期）
- [ ] リセットでデフォルト値に戻る
- [ ] テーマ・フォントサイズの変更が画面に即時反映される
