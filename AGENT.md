# AGENT.md

このリポジトリでのベンチ・資料作成の前提と現状まとめ。

## 目的
- Ruby 4.0 周辺の変更点・性能差を社内勉強会向けに整理
- 2.7.5 / 3.0.4 / 3.4.8 / 4.0.1 の比較ベンチを実施・可視化
- 資料は `docs/ruby4_presentation.md`

## 実行環境
- Docker + official ruby images
- docker-compose: `docker-compose.yml`
- イメージ: `ruby:2.7.5` `ruby:3.0.4` `ruby:3.4.8` `ruby:4.0.1`

## ベンチ構成
- 軽量（1回実行）: `benchmark/run.rb`
- heavy（5回実行・平均/中央値集計）: `benchmark/run_heavy.rb`
  - SCALE=8 で実行
  - Thread/Ractor 追加済み: `thread_sum`, `ractor_sum`
- app_like 軽量（1回実行）: `benchmark/app_like.rb`
- app_like heavy（5回実行・平均/中央値集計）: `benchmark/app_like_heavy.rb`
  - SCALE=4 で実行（2.7.5でタイムアウト回避のため）
  - Thread/Ractor 追加済み: `thread_json_parse`, `ractor_json_parse`

## 重要な仕様/注意点
- Ruby 4.0 で `Array#rfind` が追加: 4.0.1 のみ値がある
- Ractor は Ruby 3.0+ でのみ測定
- Ractor 受け取りは互換用 `ractor_take` を使用
- app_like heavy は SCALE=4 前提（資料・グラフもこの値）

## 結果ファイル
- heavy 結果JSON: `benchmark/results/heavy-*.json`
- app_like heavy 結果JSON: `benchmark/results/app_like-heavy-*.json`
- 集計表:
  - `benchmark/results/heavy_tables.md`
  - `benchmark/results/app_like_heavy_tables.md`

## グラフ
- 生成スクリプト: `benchmark/graph/generate.rb`
- 依存: `benchmark/graph/Gemfile` (gruff + rmagick)
- 生成先: `benchmark/graphs/`
- 方針:
  - heavy/app_like を「core」と「parallel」に分割
  - 相対値グラフ（baseline=3.0.4）も作成
  - 画像: PNG/SVG 両方

主要ファイル名:
- heavy core: `heavy_core_mean.*`, `heavy_core_median.*`
- heavy parallel: `heavy_parallel_mean.*`, `heavy_parallel_median.*`
- heavy core rel: `heavy_core_mean_rel.*`, `heavy_core_median_rel.*`
- heavy parallel rel: `heavy_parallel_mean_rel.*`, `heavy_parallel_median_rel.*`
- app_like core: `app_like_core_mean.*`, `app_like_core_median.*`
- app_like parallel: `app_like_parallel_mean.*`, `app_like_parallel_median.*`
- app_like core rel: `app_like_core_mean_rel.*`, `app_like_core_median_rel.*`
- app_like parallel rel: `app_like_parallel_mean_rel.*`, `app_like_parallel_median_rel.*`

## 資料
- `docs/ruby4_presentation.md`
  - heavy/app_like の平均/中央値表
  - Mermaid グラフ（分割・相対値反映）
  - 指標の詳細説明（実コードと一致）

## 生成コマンド（参考）
### heavy
```
RUNS=5 SCALE=8 docker compose run --rm ruby-2.7.5 ruby /app/benchmark/run_heavy.rb
RUNS=5 SCALE=8 docker compose run --rm ruby-3.0.4 ruby /app/benchmark/run_heavy.rb
RUNS=5 SCALE=8 docker compose run --rm ruby-3.4.8 ruby /app/benchmark/run_heavy.rb
RUNS=5 SCALE=8 docker compose run --rm ruby-4.0.1 ruby /app/benchmark/run_heavy.rb
```

### app_like heavy
```
RUNS=5 SCALE=4 docker compose run --rm ruby-2.7.5 ruby /app/benchmark/app_like_heavy.rb
RUNS=5 SCALE=4 docker compose run --rm ruby-3.0.4 ruby /app/benchmark/app_like_heavy.rb
RUNS=5 SCALE=4 docker compose run --rm ruby-3.4.8 ruby /app/benchmark/app_like_heavy.rb
RUNS=5 SCALE=4 docker compose run --rm ruby-4.0.1 ruby /app/benchmark/app_like_heavy.rb
```

### グラフ生成
```
docker run --rm -v /Users/okamura.yasushi/project/ruby4_test:/app -w /app ruby:3.4 bash -lc \
'apt-get update -y >/dev/null && apt-get install -y --no-install-recommends libmagickwand-dev >/dev/null && \
gem install bundler >/dev/null && export BUNDLE_GEMFILE=benchmark/graph/Gemfile && \
bundle config set --local path "vendor/bundle" && bundle install >/dev/null && \
bundle exec ruby benchmark/graph/generate.rb'
```
