# Morph Gate — Google Play ストア申請テキスト

---

## アプリ情報

| 項目 | 値 |
|------|-----|
| パッケージ名 | com.example.morph_gate ※要変更 |
| バージョン | 1.1.0 (versionCode 2) |
| カテゴリ | ゲーム › カジュアル |
| コンテンツレーティング | 全年齢 (Everyone) |
| 価格 | 無料（アプリ内購入あり） |

---

## タイトル（30文字以内）

**日本語**: モーフゲート
**英語**: Morph Gate

---

## 短い説明（80文字以内）

**日本語**:
形を変えてゲートを潜り抜けろ！ジェリーをモーフして壁の穴を通り抜ける爽快ゲーム

**英語**:
Morph your jelly through fantasy gates! Change shapes to pass through walls in this hypercasual runner.

---

## 詳細説明（4000文字以内）

### 日本語

```
🔮 MORPH GATE — 形を変えてゲートを突破しろ！

ジェリーキャラクターを■□★△の形に変形させ、ファンタジーゲートの穴を通り抜ける
ハイパーカジュアル × パズル × レースゲーム！

【基本ルール】
壁が迫ってくる！ボタンを押して形を変え、壁の穴の形に合わせて通り抜けろ。
2つのボタンを同時押しすると「複合形状」に変形！さらに高得点を狙おう。

【特徴】
✨ 4種類の基本形状 + 4種類の複合形状
🔥 コンボで得点倍増！最大3.0倍マルチプライヤー
👾 ジェリーが進化！5段階の進化でどんどん強くなる
👻 ゴーストレース搭載！過去最高のプレイと競え
🎭 10種類のキャラクター！コインを集めて解放しよう
📈 難易度は自動調整。Easy → Normal → Hard → Expertへ

【キャラクター一覧】
💧 スライム（初期）/ 🔥 ファイア / ❄️ アイス / 🌑 シャドウ
☣️ トキシック / ✨ ゴールデン / ⚡ サンダー / 💎 クリスタル
🌌 コズミック / 🕳️ ヴォイド

--- 10キャラ全解放を目指せ！---

【遊び方】
1. 画面下部の形状ボタンをタップ
2. 迫り来るゲートの穴と形を合わせる
3. 正確に通り抜けるほど高得点！
4. ゴースト（前回ベスト）を追い抜いてハイスコア更新！

広告を見てコインを獲得し、好みのキャラをアンロック！
```

### English

```
🔮 MORPH GATE — Morph through Fantasy Gates!

Transform your jelly character into squares, circles, stars, and triangles 
to pass through the holes in approaching fantasy gates!

【How to Play】
Walls are coming! Tap the shape buttons to morph and match the hole shape.
Press two buttons simultaneously for COMPOSITE shapes — huge bonus points!

【Features】
✨ 4 basic shapes + 4 composite shapes
🔥 Combo multiplier up to 3.0x
👾 Jelly evolution — 5 stages of awesome forms
👻 Ghost Race — compete against your best run
🎭 10 characters to unlock with coins
📈 Auto difficulty: Easy → Normal → Hard → Expert

Reach for the highest score and show off your morphing skills!
```

---

## スクリーンショット撮影ガイド

### 必要なスクリーンショット（最低3枚、最大8枚）
サイズ: 1080×1920px（縦画面、16:9 or 9:16）

| # | 場面 | 撮影内容 |
|---|------|----------|
| 1 | ホーム画面 | タイトル + ジェリーキャラクター |
| 2 | ゲームプレイ（序盤） | 形状ボタン + 壁が迫る場面 |
| 3 | コンボ中 | x2.0以上のコンボ + スコア |
| 4 | ゴーストレース | 👻バッジ表示 + GHOST BEAT! |
| 5 | キャラ選択画面 | 10キャラのグリッド表示 |
| 6 | 進化演出 | ✨進化オーバーレイ |
| 7 | ゲームオーバー | スコア表示 + NEW RECORD! |
| 8 | 設定画面 | プロフィール情報 |

### 撮影手順
```
1. 実機またはエミュレーターにAPKをインストール
2. Android: 電源ボタン + 音量下 で撮影
3. H:\マイドライブ\apps\morph_gate\store\screenshots\ に保存
4. adb pull /sdcard/Pictures/Screenshots/ でPCに取り込み可
```

---

## AdMob 本番ID 設定（リリース前に必須）

`lib/services/ad_service.dart` の以下を本番IDに変更:

```dart
static const _AdIds _prod = _AdIds(
  banner:        'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',  // ← 変更
  interstitial:  'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',  // ← 変更
  rewarded:      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',  // ← 変更
);
```

`android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>  <!-- ← 変更 -->
```

---

## パッケージ名変更（必須）

`android/app/build.gradle.kts` の `applicationId` を変更:
```kotlin
applicationId = "com.yourcompany.morphgate"  // ← 変更
```

`android/app/src/main/AndroidManifest.xml` の `package` も同様に変更。

---

## リリース署名の設定

### Step 1: キーストア生成（初回のみ）
```bash
keytool -genkey -v -keystore H:\morph_gate_release.keystore \
  -alias morph_gate -keyalg RSA -keysize 2048 -validity 10000
```

### Step 2: android/key.properties を作成
```properties
storePassword=<your_password>
keyPassword=<your_password>
keyAlias=morph_gate
storeFile=H:/morph_gate_release.keystore
```

### Step 3: android/app/build.gradle.kts に署名設定追加
```kotlin
val keystoreProperties = java.util.Properties()
val keystoreFile = rootProject.file("key.properties")
if (keystoreFile.exists()) keystoreProperties.load(keystoreFile.inputStream())

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### Step 4: key.properties を .gitignore に追加
```
android/key.properties
*.keystore
```

---

## プライバシーポリシー（必須）

Google Play は広告SDKを使用するアプリにプライバシーポリシーを要求します。
以下のサービスを使用していることを記載:
- Google AdMob（広告配信・データ収集）
- Hive（ローカルデータ保存のみ・外部送信なし）

推奨: GitHub Pages または Notion で公開ページを作成してURLを登録。

---

## リリースチェックリスト

- [ ] パッケージ名を `com.yourcompany.morphgate` に変更
- [ ] AdMob 本番IDを設定
- [ ] キーストア生成・署名設定完了
- [ ] バージョン: 1.1.0+2 ✅
- [ ] 512x512 アイコン: store/icon_512.png ✅
- [ ] フィーチャーグラフィック: store/feature_graphic_1024x500.png ✅
- [ ] スクリーンショット 3枚以上撮影
- [ ] プライバシーポリシーURL取得・登録
- [ ] コンテンツレーティング回答（Play Console内）
- [ ] リリースAPKビルド・アップロード
