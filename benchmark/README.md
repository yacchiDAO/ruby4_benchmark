# Benchmark Sample

This folder contains Ruby benchmarks used across multiple Ruby versions.

- `run.rb`: quick micro benchmark (single run)
- `run_heavy.rb`: heavier benchmark, aggregates mean/median across multiple runs
- `app_like.rb`: app-ish workloads (single run)
- `app_like_heavy.rb`: app-ish workloads, aggregates mean/median across multiple runs

## Heavy run

```bash
# 5 runs, scale factor 8 (default)
docker compose run --rm ruby-4.0.1 ruby /app/benchmark/run_heavy.rb

# custom
RUNS=5 SCALE=10 docker compose run --rm ruby-4.0.1 ruby /app/benchmark/run_heavy.rb

# app-like heavy
RUNS=5 SCALE=4 docker compose run --rm ruby-4.0.1 ruby /app/benchmark/app_like_heavy.rb
```
