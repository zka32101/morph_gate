# Morph Gate — App Store / Google Play メタデータ

## アプリ情報

| 項目 | 内容 |
|------|------|
| アプリ名 | Morph Gate |
| サブタイトル | 変身ジェリーで門をくぐれ！ |
| Bundle ID (iOS) | com.zka32.morph_gate |
| Package Name (Android) | com.zka32.morph_gate |
| バージョン | 1.0.0 |
| カテゴリ | ゲーム > アーケード / ハイパーカジュアル |
| 対象年齢 | 4+ (iOS) / Everyone (Android) |
| 言語 | 日本語 |

---

## 短い説明（80文字以内）

ジェリーを変形させて迫る門をくぐる！直感操作ハイパーカジュアルゲーム。

## 長い説明

**変身×突破！ファンタジー系ハイパーカジュアル「Morph Gate」**

ジェリーキャラを瞬時に変形させ、迫り来る門の形に合わせて突破せよ！

シンプルなタップ操作で誰でも遊べるのに、形の組み合わせが複雑になるほど
テンポよく指を動かす快感が止まらない。

---

**【ゲームの特徴】**

🟥 **4つの形状を自在に切り替え**
四角・円・星・三角の4形状をワンタップで瞬時チェンジ。
門の形に合わせて形を変え続けろ！

💎 **複合形状システム**
2つのボタンを同時押し（100ms以内）で特殊な複合形状を発動。
ここぞという場面で大コンボを決めろ！

🌟 **ジェリー進化システム**
スコアを積み上げるほどジェリーが進化。
Slime → Big Slime → Crystal → Ghost → Primordial
伝説の究極体を目指せ！

🤖 **AI難度調整**
Claude Haiku AIがプレイヤーの実力をリアルタイムで分析。
クリア率・コンボ数に応じて最適な難度を自動調整するので、
初心者でも上級者でもちょうどいい刺激が続く。

🏆 **ハイスコア記録**
あなたの最高記録をローカルに保存。
毎回更新を目指して熱中できる！

---

**【こんな方に】**
・電車の中や休憩時間にサクッと遊びたい方
・反射神経を鍛えたい方
・ゲームが上手くなるほど面白くなるやりがいを求める方
・ファンタジー世界観のかわいいキャラが好きな方

---

**【課金について】**
基本プレイ無料。広告あり（スキップ可のリワード広告）。

---

## キーワード（ASO）

ハイパーカジュアル,変身,パズル,アーケード,反射神経,無料,ジェリー,形合わせ,暇つぶし,脳トレ

---

## スクリーンショットシナリオ（6枚）

1. **ホーム画面** — ジェリーキャラのアニメーション、ハイスコア表示
2. **ゲームプレイ** — 円形の門に向かって円形ジェリーが突進する瞬間
3. **複合形状** — 2ボタン同時押しで特殊形状、コンボカウント表示
4. **ジェリー進化** — Crystal 進化シーン、進化ストーリーテキスト
5. **ゲームオーバー** — スコア表示、リトライ/共有ボタン
6. **設定画面** — 難度・音量・Claude AI設定

### 推奨スクリーンショットサイズ
- iPhone 6.9" (1320×2868)
- iPhone 6.5" (1242×2688)
- iPad Pro 12.9" (2048×2732)

---

## AdMob 設定（本番時に差し替え）

### Android
`android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

### iOS
`ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

### 広告ユニットID
`lib/services/ad_service.dart` の `_prod*` 定数を差し替え:
```dart
static const String _prodBanner       = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
static const String _prodInterstitial = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
static const String _prodRewarded     = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
```

---

## Claude / Gemini API設定

`.env` ファイルに実際のキーを設定（`.gitignore` に追加済みか確認）:

```
CLAUDE_API_KEY=sk-ant-...
GEMINI_API_KEY=AIza...
```

---

## App Store Connect — 審査メモ

- デモアカウント不要
- AdMob は本番ID設定後に審査提出
- Claude AI難度調整は広告なし端末でも動作（フォールバック実装済み）
