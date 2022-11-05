# ecs-fargate-dockerhub-image-pull

[ECS on Fargate構成でDocker Hubの認証情報を扱う](https://dev.classmethod.jp/articles/authenticating-with-docker-hub-for-aws-container-services/)で利用したサンプルコードになります。

# 構成図

1. シークレットマネージャーを利用してDocker Hubの認証情報を保管します。
2. 保管した認証情報を利用してタスク実行ロールで取得しコンテナイメージの取得を行う。

<img src="/image/構成図.png">