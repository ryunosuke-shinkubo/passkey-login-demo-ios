# 新しいPCでのセットアップ手順

## 1. 事前準備

以下を新しいPCに準備します。

- macOS
- Xcode
- Git
- Apple Developerアカウント
- リポジトリへのアクセス権

Xcodeは、開発時に使用するiOS SDKに対応したバージョンを使用してください。

## 2. リポジトリを取得する

ターミナルでリポジトリをcloneします。

```bash
git clone <リポジトリURL>
cd PasskeyRedirectDemo
```

`PasskeyRedirectDemo.xcodeproj`がリポジトリに含まれている場合は、Xcodeで以下を開きます。

```text
PasskeyRedirectDemo.xcodeproj
```

`.xcodeproj`が含まれていない場合は、XcodeでiOS Appプロジェクトを作成し、次のファイルを追加してください。

- `ContentView.swift`
- `PasskeyRedirectDemoApp.swift`
- `PasskeyRedirectViewModel.swift`
- `Assets.xcassets`
- `PasskeyRedirectDemo.entitlements`

プロジェクト設定で、アプリのターゲットに`.entitlements`ファイルを紐付けます。

## 3. Signing設定を確認する

Xcodeでプロジェクトのアプリターゲットを開き、以下を設定します。

1. `Signing & Capabilities`を開く
2. `Team`に自分のApple Developerチームを設定する
3. `Bundle Identifier`を確認・設定する
4. 自動署名を使用する場合は`Automatically manage signing`を有効にする

Bundle Identifierを変更した場合は、ユニバーサルリンク側の設定も同じ値に変更する必要があります。

## 4. Associated Domainsを設定する

`Signing & Capabilities`に**Associated Domains** capabilityを追加し、以下のドメインを設定します。

```text
applinks:ryunosuke-shinkubo.github.io
```

`PasskeyRedirectDemo.entitlements`に同じ設定が入っていることも確認してください。

## 5. Web側の設定を確認する

ユニバーサルリンクでアプリに復帰するには、`redirect_uri`に使用するドメイン側で以下が必要です。

- Apple App Site Association（AASA）ファイルの配置
- AASAファイル内へのアプリのBundle Identifierの登録
- 認証サーバーでの`redirect_uri`の許可・登録
- 認証後に`shortTimeCode`、`state`、または`error`をクエリパラメータとして付けてリダイレクトする処理

現在の初期値は以下です。

```text
ログイン開始URL: https://stg-trade.sbifxt.co.jp/mpage/pf-login.html
redirect_uri: https://ryunosuke-shinkubo.github.io/auth/callback.html
```

環境が変わる場合は、画面上のURLまたは`PasskeyRedirectViewModel.swift`の初期値を変更します。

## 6. ビルド・実機確認

1. Xcodeで実機またはシミュレーターを選択する
2. `⌘B`でビルドする
3. 実機でアプリを起動する
4. 「ログイン開始」を押す
5. 認証後にアプリへ戻ることを確認する
6. `shortTimeCode`、`state`、`error`が画面に表示されることを確認する
7. `state`が「一致しました」と表示されることを確認する

ユニバーサルリンクの確認は、シミュレーターよりも実機で行うことを推奨します。

## 7. トラブルシューティング

### ビルドできない

- Teamが正しく設定されているか確認する
- Bundle Identifierが重複していないか確認する
- `.entitlements`ファイルがターゲットに紐付いているか確認する
- XcodeのSigningエラー内容を確認する

### 認証後にアプリへ戻らない

- Associated Domainsの設定を確認する
- `redirect_uri`のドメインとAssociated Domainsのドメインが一致しているか確認する
- AASAファイルのBundle Identifierが一致しているか確認する
- 実機で確認する

### `state`が一致しない

- 認証開始後に古いコールバックURLを開いていないか確認する
- 認証サーバーが受け取った`state`をそのまま返しているか確認する
- 複数回ログインを開始していないか確認する

## 8. 変更時に確認するファイル

- 画面や表示の変更：`ContentView.swift`
- URL生成・コールバック解析の変更：`PasskeyRedirectViewModel.swift`
- アプリ復帰処理の変更：`PasskeyRedirectDemoApp.swift`
- ユニバーサルリンク設定の変更：`PasskeyRedirectDemo.entitlements`
- セットアップ手順の変更：`SETUP.md`

## 9. リポジトリに含めるファイル

Xcodeプロジェクトを共有する場合は、少なくとも以下をリポジトリに含めます。

```text
PasskeyRedirectDemo.xcodeproj/
├── project.pbxproj
├── project.xcworkspace/
│   └── contents.xcworkspacedata
└── xcshareddata/
    └── xcschemes/
        └── PasskeyRedirectDemo.xcscheme
```

`xcuserdata`、`*.xcuserstate`、`DerivedData`、`build`などの個人環境依存ファイルや生成物は含めません。
