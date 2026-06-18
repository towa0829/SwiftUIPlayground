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

## Step 3 — AppStorage で設定値を永続化する
**ファイル:** `Views/SettingsView.swift` の先頭に追記

### 3-1: AppStorage プロパティを宣言
```swift
struct SettingsView: View {
    // UserDefaults のキーと型を指定するだけで自動同期される
    @AppStorage("app_theme")            private var appTheme: String = AppTheme.system.rawValue
    @AppStorage("font_size")            private var fontSize: String = FontSize.medium.rawValue
    @AppStorage("notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("username")             private var username: String = ""
```
▶ ここで確認: ビルドエラーがないこと

### 3-2: 動作確認用に値を表示するだけのViewを一時的に作る
```swift
                Section("現在の値（確認用）") {
                    Text("テーマ: \(appTheme)")
                    Text("フォント: \(fontSize)")
                    Text("通知: \(notificationsEnabled.description)")
                }
```
▶ ここで確認: アプリ終了・再起動後も値が保持されること（シミュレーターで確認）

---

## Step 4 — Toggle を実装する
**ファイル:** `Views/SettingsView.swift` の「通知」セクションを編集

### 4-1: Toggle の基本形
```swift
                Section("通知") {
                    // isOn: に $binding を渡すことで Toggle が値を書き換える
                    Toggle("通知を受け取る", isOn: $notificationsEnabled)
                }
```
▶ ここで確認: トグルをON/OFFするとStep 3の確認用テキストが切り替わること

### 4-2: if で関連項目を条件表示
```swift
                Section("通知") {
                    Toggle("通知を受け取る", isOn: $notificationsEnabled)

                    // notificationsEnabled が true の時だけ表示される
                    if notificationsEnabled {
                        Toggle("サウンド", isOn: $soundEnabled)
                        Toggle("バイブレーション", isOn: $hapticsEnabled)
                    }
                }
```
（`soundEnabled` と `hapticsEnabled` の @AppStorage も先頭に追加する）

▶ ここで確認: 「通知」をOFFにすると「サウンド」「バイブレーション」が消えること

---

## Step 5 — Picker を実装する
**ファイル:** `Views/SettingsView.swift` の「外観」セクションを編集

### 5-1: Picker の基本形（デフォルト: メニュースタイル）
```swift
                Section("外観") {
                    Picker("テーマ", selection: $appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme.rawValue)
                        }
                    }
                }
```
▶ ここで確認: タップするとドロップダウンで選択肢が出ること

### 5-2: .pickerStyle を変えて違いを体感する
```swift
                    Picker("フォントサイズ", selection: $fontSize) {
                        ForEach(FontSize.allCases) { size in
                            Text(size.rawValue).tag(size.rawValue)
                        }
                    }
                    // .pickerStyle(.segmented) を試してみる
```

### 5-3: NavigationLink スタイルのピッカー（別画面で選択）
```swift
                    Picker("言語", selection: $language) {
                        ForEach(Language.allCases) { lang in
                            Text(lang.rawValue).tag(lang.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
```
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
                            TextField("ユーザー名", text: $username)
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
```swift
                Section("セキュリティ") {
                    Toggle("自動ロック", isOn: $autoLock)
                    NavigationLink("パスワードを変更") {
                        Text("パスワード変更画面")
                            .navigationTitle("パスワード変更")
                    }
                }
```

### 6-3: リセットボタン + Alert
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
                    // UserDefaults をクリア
                    let defaults = UserDefaults.standard
                    ["app_theme","font_size","notifications_enabled","username"].forEach {
                        defaults.removeObject(forKey: $0)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("すべての設定がデフォルトに戻ります。")
            }
```
▶ ここで確認: リセット後に設定値がデフォルトに戻ること

---

## 完成チェックリスト
- [ ] 5つのセクションが表示される
- [ ] Toggle のON/OFFが即反映される
- [ ] 通知OFFで子設定が非表示になる
- [ ] 3種類のPickerスタイルを確認した
- [ ] アプリ再起動後も設定値が保持される（AppStorage の動作確認）
- [ ] リセットでデフォルト値に戻る

---

## 改良ノート（写経後の修正）
- テーマ（ライト/ダーク/システム）とフォントサイズを `SettingsViewModel` 経由でルートに実際に配線し、見た目に反映されるようにした（写経時点では設定項目を保持するだけで効果がなかった）。
- 「すべての設定をリセット」が `UserDefaults` を直接書き換えるだけでUIに即反映されない問題を修正し、リセット後すぐに表示が変わるようにした。
- `PasswordPlaceholderView` を `Views/SettingsView.swift` から独立ファイルへ分離（`#Preview` 付き）。
