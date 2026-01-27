# frozen_string_literal: true

require "benchmark"
require "csv"
require "erb"
require "json"
require "stringio"

RUNS = (ENV["RUNS"] || "5").to_i
SCALE = (ENV["SCALE"] || "4").to_i

suite = {}

thread_workers = 4
thread_json_iters = 50 * SCALE
thread_parse_payload = begin
  data = (1..(1000 * SCALE)).map do |i|
    { id: i, name: "user#{i}", roles: ["user", "editor"], flags: (1..20).to_a }
  end
  json = JSON.dump(data)
  defined?(Ractor) ? Ractor.make_shareable(json) : json
end

suite["erb_render"] = lambda do
  template = ERB.new("<ul><% items.each do |item| %><li><%= item %></li><% end %></ul>")
  items = (1..(200 * SCALE)).map { |i| "item-#{i}" }
  (300 * SCALE).times { template.result_with_hash(items: items) }
end

suite["json_large"] = lambda do
  data = (1..(1000 * SCALE)).map do |i|
    { id: i, name: "user#{i}", roles: ["user", "editor"], flags: (1..20).to_a }
  end
  json = JSON.dump(data)
  JSON.parse(json)
end

suite["csv_generate"] = lambda do
  rows = (1..(5000 * SCALE)).map { |i| [i, "name#{i}", i % 5, "2026-01-25"] }
  CSV.generate do |csv|
    rows.each { |row| csv << row }
  end
end

suite["stringio_build"] = lambda do
  io = StringIO.new
  (100_000 * SCALE).times { |i| io << "line" << i.to_s << "\n" }
  io.string
end

suite["router_sim"] = lambda do
  routes = { "/" => "home", "/users" => "users", "/users/:id" => "user" }
  (100_000 * SCALE).times do |i|
    path = (i % 2).zero? ? "/users/#{i}" : "/"
    if path.start_with?("/users/")
      routes["/users/:id"]
    else
      routes[path]
    end
  end
end

suite["thread_json_parse"] = lambda do
  threads = thread_workers.times.map do
    Thread.new do
      thread_json_iters.times { JSON.parse(thread_parse_payload) }
    end
  end
  threads.each(&:join)
end

if defined?(Ractor)
  suite["ractor_json_parse"] = lambda do
    ractors = thread_workers.times.map do
      Ractor.new(thread_parse_payload, thread_json_iters) do |payload, iters|
        iters.times { JSON.parse(payload) }
        true
      end
    end
    ractors.each { |r| ractor_take(r) }
  end
end

results = Hash.new { |h, k| h[k] = [] }

def ractor_take(r)
  return r.take if r.respond_to?(:take)
  return r.value if r.respond_to?(:value)
  return r.receive if r.respond_to?(:receive)

  _r, v = Ractor.select(r)
  v
end

RUNS.times do
  suite.each do |label, block|
    t = Benchmark.realtime { block.call }
    results[label] << t
  end
  GC.start
end

summary = {}
results.each do |label, runs|
  sorted = runs.sort
  median = sorted[sorted.size / 2]
  mean = runs.sum / runs.size
  summary[label] = {
    "mean" => mean,
    "median" => median,
    "runs" => runs
  }
end

puts JSON.pretty_generate({
  "ruby_version" => RUBY_VERSION,
  "runs" => RUNS,
  "scale" => SCALE,
  "summary" => summary
})
