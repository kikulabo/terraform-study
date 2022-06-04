## 事前準備

tfenv をインストールする

```
brew install tfenv
```

## 使い方

1. 初期化

```
terraform init
```

2. テスト

```
terraform plan
```

3. 適用

```
terraform apply
```

4. DNS が出力されるのアクセスしてページが表示されることを確認する

例）

```
Outputs:

ec2_dns = "ec2-*-*-*-*.ap-northeast-1.compute.amazonaws.com"
```

5. お片付け（削除）

```
terraform destroy
```

