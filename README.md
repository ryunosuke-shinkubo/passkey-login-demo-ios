# Passkey Redirect Demo

Passkey 認証の開始 URL に対して `state` と `redirect_uri` を付与し、認証後のコールバック URL から `shortTimeCode` / `state` / `error` を受け取って表示する iOS デモアプリです。

## できること

- ログイン開始 URL を指定して外部ブラウザを開く
- `state` を生成してリクエストに付与する
- `redirect_uri` をログイン開始 URL に渡す
- アプリへの戻り URL から `shortTimeCode` を受け取る
- `state` の一致確認を行う
- `error` が返ってきた場合に表示する
- 受信したコールバック URL を画面上で確認する

## 画面構成

### ログイン開始設定

- **ログイン開始 URL**  
  認証開始用の URL を入力します。初期値は以下です。
  - `https://stg-trade.sbifxt.co.jp/mpage/pf-login.html`

- **redirect URL**  
  認証後にアプリへ戻すための URL を入力します。初期値は以下です。
  - `https://ryunosuke-shinkubo.github.io/auth/callback.html`

- **ブラウザ起動方式**
  - `OS既定ブラウザ`
  - `SFSafariViewController`

- **ログイン開始**
  - 押すとログイン開始 URL に遷移します
  - URL に `state` と `redirect_uri` が付与されます

### 送信されるリクエストパラメータ

ログイン開始時に以下を送信します。

- `state`: アプリ側で毎回生成するランダム値
- `redirect_uri`: コールバック先 URL

### コールバック例

`redirect_uri` にクエリを付けて戻すと、アプリが前面復帰します。

例:

```text
https://ryunosuke-shinkubo.github.io/auth/callback.html?shortTimeCode=123456&state=abcdef
```

### 受信結果

コールバックで受け取った以下を表示します。

- `shortTimeCode`
- `state`
- `error`
- 受信したコールバック URL
- `state` の一致結果

## 動作仕様

### 1. ログイン開始

`ログイン開始` を押すと、アプリは `pendingState` を新しく生成します。  
その後、ログイン開始 URL に以下のクエリを付けて開きます。

```text
state=<生成したstate>
redirect_uri=<入力したredirect URL>
```

### 2. コールバック受信

アプリは `.onOpenURL` で戻り URL を受け取ります。  
その URL のクエリから以下を読み取ります。

- `shortTimeCode`
- `code`（`shortTimeCode` が無い場合のフォールバック）
- `state`
- `error`

### 3. state 確認

受信した `state` と、ログイン開始時に生成した `state` を比較します。  
一致しない場合は、別セッションの戻り値または改ざんの可能性があるものとして表示します。

## `shortTimeCode` について

`shortTimeCode` はレスポンス本文ではなく、**コールバック URL のクエリパラメータ**として受け取ります。  
`shortTimeCode` が無い場合は `code` を代わりに参照します。

## ブラウザ起動方式の違い

- **OS既定ブラウザ**
  - `openURL` で外部ブラウザを起動します
- **SFSafariViewController**
  - アプリ内に Safari View を表示します

## 前提

- iOS アプリとして Xcode で実行できる環境
- コールバック用 URL スキームまたはユニバーサルリンク設定
- 認証先サーバーが `redirect_uri` にリダイレクトできること

## ユニバーサルリンクについて

このアプリは、認証後の戻り先として**ユニバーサルリンク**でも動作させる想定です。  
サーバーが `redirect_uri` に対してユニバーサルリンク形式のURLを返すと、iOS がアプリを前面に戻し、`onOpenURL` でコールバックを受け取ります。

利用する場合は、次の設定が必要です。

- Apple App Site Association (AASA) の設定
- 対象ドメインの Associated Domains 設定
- `redirect_uri` をアプリに紐づいた HTTPS URL にすること

## 補足

- `.gitignore` は Xcode / macOS / SwiftPM の生成物を除外しています
- `redirect_url` ではなく `redirect_uri` を使用します
