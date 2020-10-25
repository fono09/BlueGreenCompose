# BlueGreenCompose

## これは何
docker-composeだけで無理やりBlueGreenDeploymentするキット

## 内容物
* シェルスクリプト `autodeploy.sh`
* 設定ファイル `autodeploy.json`
* 動作サンプル (それ以外全部)

## 試し方

```shell
$ docker-compose up -d --build netcat_server_blue nginx curl_client
$ ./autodeploy.sh
```

## 導入方法

1. Webサーバのコンテナのログ出力に`GET` `POST`が出るようにする
1. このリポジトリの`docker-compose.yml`を見て`netcat_server(_blue,_green)?`を見て真似する
1. このリポジトリをフォークしてサブモジュールに入れる
1. `autodeploy.json` を編集していい感じにする 

## 設定方法

基本的に `autodeploy.json`を触ればできる

* `$.docker_compose_path`
`docker-compose.yml` ファイルの置き場所(スクリプトからの相対パス)
* `$.environments.(blue|green).name`
交代交代で実行されるサービスの名前
* `$.startup.timeout`
`healthy`になるまで何秒待つか
* `$.working.timeout`
ログの出力を何秒間観測しながら待つか
* `$.working.threshold`
ログの出力中に`GET` `POST`が何個出現したら動作していると見なすか
* `$.working.samples`
ログの出力を何行サンプリングするか
* `$.shutdown.timeout`
交代し終わったコンテナの停止で何秒待つか

