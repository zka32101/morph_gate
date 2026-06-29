# Morph Gate — 配布ガイド

## 事前設定チェック

### 1. .env ファイル設定
`.env` に実際の API キーを入力（`.gitignore` に含まれているか確認）:
```
CLAUDE_API_KEY=sk-ant-...
GEMINI_API_KEY=AIza...
```

### 2. AdMob 本番ID差し替え
`lib/services/ad_service.dart` の `_prod*` 定数を実際の AdMob 広告ユニット ID に差し替える。
`android/app/src/main/AndroidManifest.xml` の `APPLICATION_ID` も差し替え。
`ios/Runner/Info.plist` の `GADApplicationIdentifier` も差し替え。

---

## Android — Google Play

### 署名キー作成（初回のみ）

```bash
keytool -genkey -v \
  -keystore C:\apk\morph_gate-keystore.jks \
  -alias morph_gate \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=MorphGate, OU=ZKA32, O=ZKA32, L=Tokyo, ST=Tokyo, C=JP"
```

### key.properties 作成

`android/key.properties`（git管理外）:
```
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=morph_gate
storeFile=C:\\apk\\morph_gate-keystore.jks
```

### build.gradle.kts に署名設定追加

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias      = keyProperties["keyAlias"] as String
            keyPassword   = keyProperties["keyPassword"] as String
            storeFile     = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }
    buildTypes {
        release { signingConfig = signingConfigs.getByName("release") }
    }
}
```

### リリースAPKビルド

```bash
APPNAME="morph_gate"
SRC="H:/マイドライブ/apps/$APPNAME"
DST="/c/apk/$APPNAME"

for item in lib assets android ios pubspec.yaml pubspec.lock .env; do
  [ -e "$SRC/$item" ] && cp -r "$SRC/$item" "$DST/"
done
cd "$DST" && flutter pub get
flutter build apk --release --no-tree-shake-icons

cp build/app/outputs/flutter-apk/app-release.apk \
   "H:/マイドライブ/apk/${APPNAME}-app-release.apk"
```

> **注意**: `.env` も必ずコピーすること（AI機能に必要）

---

## iOS — TestFlight

```bash
open "H:\マイドライブ\apps\morph_gate\ios\Runner.xcworkspace"
```

Xcodeで設定:
- Bundle Identifier: `com.zka32.morph_gate`
- Deployment Target: iOS 14.0
- Signing: Apple Developer チームを選択

```
Product → Archive → Distribute App → App Store Connect
```

---

## バージョン管理

| バージョン | 内容 |
|-----------|------|
| 1.0.0+1 | MVP: 4形状・複合・進化・AI難度・ハイスコア |
| 1.1.0+2 | v1.1: ゴーストレース・門図鑑・キャラ×10 |

---

## チェックリスト

### 必須（v1.0リリース）
- [ ] `.env` に実際のAPIキー入力
- [ ] AdMob 本番 App ID & 広告ユニット ID 差し替え
- [ ] 署名キー作成
- [ ] リリースAPKビルド（署名付き）
- [ ] Google Play Console アプリ登録
- [ ] スクリーンショット 2枚以上
- [ ] プライバシーポリシーURL設定

### 推奨（v1.1）
- [ ] BGM/SE 音声ファイル追加
- [ ] ゴーストレース機能
- [ ] キャラクター×10体
- [ ] 門コレクション図鑑
