# Ruby 4.0 Benchmark Playground

Ruby 2.7.5 / 3.0.4 / 3.4.8 / 4.0.1 を Docker 上で比較するベンチマーク一式です。
社内勉強会向けの資料とベンチ結果の可視化が目的です。

## 構成
- `docker/` : Ruby各バージョンのDockerfile
- `docker-compose.yml` : ビルド/実行用
- `benchmark/` : ベンチスクリプト
  - `run.rb` : 軽量（1回実行）
  - `run_heavy.rb` : heavy（5回実行・平均/中央値）
  - `app_like.rb` : アプリ寄り軽量
  - `app_like_heavy.rb` : アプリ寄りheavy（5回実行・平均/中央値）
  - `graph/` : グラフ生成スクリプト（gruff）
- `benchmark/results/` : ベンチ結果JSON/集計表
- `benchmark/graphs/` : PNG/SVGグラフ
- `docs/` : 発表資料（Git管理外）

## 前提
- Docker が利用可能であること
- ベンチは `docker compose run` で実行

## ベンチ実行
### Build
```
docker compose build
```

### 軽量（1回実行）
```
docker compose run --rm ruby-2.7.5
```

### heavy（RUNS=5, SCALE=8）
```
RUNS=5 SCALE=8 docker compose run --rm ruby-2.7.5 ruby /app/benchmark/run_heavy.rb
RUNS=5 SCALE=8 docker compose run --rm ruby-3.0.4 ruby /app/benchmark/run_heavy.rb
RUNS=5 SCALE=8 docker compose run --rm ruby-3.4.8 ruby /app/benchmark/run_heavy.rb
RUNS=5 SCALE=8 docker compose run --rm ruby-4.0.1 ruby /app/benchmark/run_heavy.rb
```

### app_like heavy（RUNS=5, SCALE=4）
```
RUNS=5 SCALE=4 docker compose run --rm ruby-2.7.5 ruby /app/benchmark/app_like_heavy.rb
RUNS=5 SCALE=4 docker compose run --rm ruby-3.0.4 ruby /app/benchmark/app_like_heavy.rb
RUNS=5 SCALE=4 docker compose run --rm ruby-3.4.8 ruby /app/benchmark/app_like_heavy.rb
RUNS=5 SCALE=4 docker compose run --rm ruby-4.0.1 ruby /app/benchmark/app_like_heavy.rb
```

## グラフ生成
`benchmark/graph/Gemfile` の gruff + rmagick を利用します。

```
docker run --rm -v /Users/okamura.yasushi/project/ruby4_test:/app -w /app ruby:3.4 bash -lc \
'apt-get update -y >/dev/null && apt-get install -y --no-install-recommends libmagickwand-dev >/dev/null && \
 gem install bundler >/dev/null && export BUNDLE_GEMFILE=benchmark/graph/Gemfile && \
 bundle config set --local path "vendor/bundle" && bundle install >/dev/null && \
 bundle exec ruby benchmark/graph/generate.rb'
```

## 出力
- 結果JSON: `benchmark/results/`
- 集計表: `benchmark/results/heavy_tables.md`, `benchmark/results/app_like_heavy_tables.md`
- グラフ: `benchmark/graphs/`

## 補足
- `docs/` 以下は `.gitignore` 対象
- Ractorは Ruby 3.0+ のみ実行
- `Array#rfind` は Ruby 4.0+ のみ実行
