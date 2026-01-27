# frozen_string_literal: true

require "json"
require "gruff"

VERSIONS = ["2.7.5", "3.0.4", "3.4.8", "4.0.1"].freeze
BASELINE_VERSION = "3.0.4"

HEAVY_FILES = {
  "2.7.5" => "benchmark/results/heavy-2.7.5.json",
  "3.0.4" => "benchmark/results/heavy-3.0.4.json",
  "3.4.8" => "benchmark/results/heavy-3.4.8.json",
  "4.0.1" => "benchmark/results/heavy-4.0.1.json",
}.freeze

APP_LIKE_FILES = {
  "2.7.5" => "benchmark/results/app_like-heavy-2.7.5.json",
  "3.0.4" => "benchmark/results/app_like-heavy-3.0.4.json",
  "3.4.8" => "benchmark/results/app_like-heavy-3.4.8.json",
  "4.0.1" => "benchmark/results/app_like-heavy-4.0.1.json",
}.freeze

HEAVY_BENCHES = %w[
  fib_rec
  array_sort
  hash_count
  class_new_kwargs
  string_ivar_access
  class_hash
  class_object_id
  array_find
  array_rfind
  array_rev_find
  regex_scan
  json_round
  thread_sum
  ractor_sum
].freeze

APP_BENCHES = %w[
  erb_render
  json_large
  csv_generate
  stringio_build
  router_sim
  thread_json_parse
  ractor_json_parse
].freeze

HEAVY_CORE_BENCHES = HEAVY_BENCHES - %w[thread_sum ractor_sum]
HEAVY_PAR_BENCHES = %w[thread_sum ractor_sum].freeze

APP_CORE_BENCHES = APP_BENCHES - %w[thread_json_parse ractor_json_parse]
APP_PAR_BENCHES = %w[thread_json_parse ractor_json_parse].freeze

OUTPUT_DIR = "benchmark/graphs"

HEAVY_LABELS = {
  "fib_rec" => "fib_rec",
  "array_sort" => "array_sort",
  "hash_count" => "hash_count",
  "class_new_kwargs" => "class_new_kwargs",
  "string_ivar_access" => "string_ivar_access",
  "class_hash" => "class_hash",
  "class_object_id" => "class_object_id",
  "array_find" => "array_find",
  "array_rfind" => "array_rfind",
  "array_rev_find" => "array_rev_find",
  "regex_scan" => "regex_scan",
  "json_round" => "json_round",
  "thread_sum" => "thread_sum",
  "ractor_sum" => "ractor_sum",
}.freeze

APP_LABELS = {
  "erb_render" => "erb_render",
  "json_large" => "json_large",
  "csv_generate" => "csv_generate",
  "stringio_build" => "stringio_build",
  "router_sim" => "router_sim",
  "thread_json_parse" => "thread_json_parse",
  "ractor_json_parse" => "ractor_json_parse",
}.freeze


def load_summary(files)
  files.transform_values do |path|
    JSON.parse(File.read(path)).fetch("summary")
  end
end

def series_for(summary, benches, key)
  VERSIONS.map do |ver|
    data = summary[ver]
    benches.map do |bench|
      entry = data[bench]
      entry ? entry[key] : 0.0
    end
  end
end

def relative_series_for(summary, benches, key, baseline_version)
  baseline = summary.fetch(baseline_version)
  VERSIONS.map do |ver|
    data = summary[ver]
    benches.map do |bench|
      entry = data[bench]
      base = baseline[bench]
      next 0.0 unless entry && base && base[key].to_f > 0.0

      entry[key] / base[key]
    end
  end
end

def render_bar(title, benches, series, out_base, max_value: nil, labels: nil)
  g = Gruff::Bar.new(1600)
  g.title = title
  g.theme = Gruff::Themes::PASTEL
  g.legend_font_size = 16
  g.marker_font_size = 14
  g.label_font_size = 14 if g.respond_to?(:label_font_size=)
  g.title_font_size = 22
  g.hide_labels = false if g.respond_to?(:hide_labels=)
  g.label_rotation = 45 if g.respond_to?(:label_rotation=)
  g.bottom_margin = 140 if g.respond_to?(:bottom_margin=)
  g.labels = benches.each_with_index.to_h { |b, i| [i, labels ? labels.fetch(b, b) : b] }
  g.maximum_value = max_value if max_value

  VERSIONS.each_with_index do |ver, idx|
    g.data(ver, series[idx])
  end

  g.write(File.join(OUTPUT_DIR, "#{out_base}.png"))
  g.write(File.join(OUTPUT_DIR, "#{out_base}.svg"))
end

heavy = load_summary(HEAVY_FILES)
app_like = load_summary(APP_LIKE_FILES)

heavy_mean = series_for(heavy, HEAVY_BENCHES, "mean")
heavy_median = series_for(heavy, HEAVY_BENCHES, "median")
heavy_mean_rel = relative_series_for(heavy, HEAVY_BENCHES, "mean", BASELINE_VERSION)
heavy_median_rel = relative_series_for(heavy, HEAVY_BENCHES, "median", BASELINE_VERSION)

app_mean = series_for(app_like, APP_BENCHES, "mean")
app_median = series_for(app_like, APP_BENCHES, "median")
app_mean_rel = relative_series_for(app_like, APP_BENCHES, "mean", BASELINE_VERSION)
app_median_rel = relative_series_for(app_like, APP_BENCHES, "median", BASELINE_VERSION)

heavy_core_max = (
  series_for(heavy, HEAVY_CORE_BENCHES, "mean").flatten +
  series_for(heavy, HEAVY_CORE_BENCHES, "median").flatten
).max * 1.1
heavy_par_max = (
  series_for(heavy, HEAVY_PAR_BENCHES, "mean").flatten +
  series_for(heavy, HEAVY_PAR_BENCHES, "median").flatten
).max * 1.1

app_core_max = (
  series_for(app_like, APP_CORE_BENCHES, "mean").flatten +
  series_for(app_like, APP_CORE_BENCHES, "median").flatten
).max * 1.1
app_par_max = (
  series_for(app_like, APP_PAR_BENCHES, "mean").flatten +
  series_for(app_like, APP_PAR_BENCHES, "median").flatten
).max * 1.1

heavy_rel_max = (heavy_mean_rel.flatten + heavy_median_rel.flatten).max * 1.1
app_rel_max = (app_mean_rel.flatten + app_median_rel.flatten).max * 1.1

render_bar("Heavy Core Mean (RUNS=5, SCALE=8)", HEAVY_CORE_BENCHES,
           series_for(heavy, HEAVY_CORE_BENCHES, "mean"), "heavy_core_mean",
           max_value: heavy_core_max, labels: HEAVY_LABELS)
render_bar("Heavy Core Median (RUNS=5, SCALE=8)", HEAVY_CORE_BENCHES,
           series_for(heavy, HEAVY_CORE_BENCHES, "median"), "heavy_core_median",
           max_value: heavy_core_max, labels: HEAVY_LABELS)
render_bar("Heavy Parallel Mean (RUNS=5, SCALE=8)", HEAVY_PAR_BENCHES,
           series_for(heavy, HEAVY_PAR_BENCHES, "mean"), "heavy_parallel_mean",
           max_value: heavy_par_max, labels: HEAVY_LABELS)
render_bar("Heavy Parallel Median (RUNS=5, SCALE=8)", HEAVY_PAR_BENCHES,
           series_for(heavy, HEAVY_PAR_BENCHES, "median"), "heavy_parallel_median",
           max_value: heavy_par_max, labels: HEAVY_LABELS)

render_bar("Heavy Core Mean (rel to #{BASELINE_VERSION})", HEAVY_CORE_BENCHES,
           relative_series_for(heavy, HEAVY_CORE_BENCHES, "mean", BASELINE_VERSION),
           "heavy_core_mean_rel", max_value: heavy_rel_max, labels: HEAVY_LABELS)
render_bar("Heavy Core Median (rel to #{BASELINE_VERSION})", HEAVY_CORE_BENCHES,
           relative_series_for(heavy, HEAVY_CORE_BENCHES, "median", BASELINE_VERSION),
           "heavy_core_median_rel", max_value: heavy_rel_max, labels: HEAVY_LABELS)
render_bar("Heavy Parallel Mean (rel to #{BASELINE_VERSION})", HEAVY_PAR_BENCHES,
           relative_series_for(heavy, HEAVY_PAR_BENCHES, "mean", BASELINE_VERSION),
           "heavy_parallel_mean_rel", max_value: heavy_rel_max, labels: HEAVY_LABELS)
render_bar("Heavy Parallel Median (rel to #{BASELINE_VERSION})", HEAVY_PAR_BENCHES,
           relative_series_for(heavy, HEAVY_PAR_BENCHES, "median", BASELINE_VERSION),
           "heavy_parallel_median_rel", max_value: heavy_rel_max, labels: HEAVY_LABELS)

render_bar("App-like Core Mean (RUNS=5, SCALE=4)", APP_CORE_BENCHES,
           series_for(app_like, APP_CORE_BENCHES, "mean"), "app_like_core_mean",
           max_value: app_core_max, labels: APP_LABELS)
render_bar("App-like Core Median (RUNS=5, SCALE=4)", APP_CORE_BENCHES,
           series_for(app_like, APP_CORE_BENCHES, "median"), "app_like_core_median",
           max_value: app_core_max, labels: APP_LABELS)
render_bar("App-like Parallel Mean (RUNS=5, SCALE=4)", APP_PAR_BENCHES,
           series_for(app_like, APP_PAR_BENCHES, "mean"), "app_like_parallel_mean",
           max_value: app_par_max, labels: APP_LABELS)
render_bar("App-like Parallel Median (RUNS=5, SCALE=4)", APP_PAR_BENCHES,
           series_for(app_like, APP_PAR_BENCHES, "median"), "app_like_parallel_median",
           max_value: app_par_max, labels: APP_LABELS)

render_bar("App-like Core Mean (rel to #{BASELINE_VERSION})", APP_CORE_BENCHES,
           relative_series_for(app_like, APP_CORE_BENCHES, "mean", BASELINE_VERSION),
           "app_like_core_mean_rel", max_value: app_rel_max, labels: APP_LABELS)
render_bar("App-like Core Median (rel to #{BASELINE_VERSION})", APP_CORE_BENCHES,
           relative_series_for(app_like, APP_CORE_BENCHES, "median", BASELINE_VERSION),
           "app_like_core_median_rel", max_value: app_rel_max, labels: APP_LABELS)
render_bar("App-like Parallel Mean (rel to #{BASELINE_VERSION})", APP_PAR_BENCHES,
           relative_series_for(app_like, APP_PAR_BENCHES, "mean", BASELINE_VERSION),
           "app_like_parallel_mean_rel", max_value: app_rel_max, labels: APP_LABELS)
render_bar("App-like Parallel Median (rel to #{BASELINE_VERSION})", APP_PAR_BENCHES,
           relative_series_for(app_like, APP_PAR_BENCHES, "median", BASELINE_VERSION),
           "app_like_parallel_median_rel", max_value: app_rel_max, labels: APP_LABELS)

puts "Wrote graphs to #{OUTPUT_DIR}"
