# frozen_string_literal: true

require "benchmark"
require "json"

RUNS = (ENV["RUNS"] || "5").to_i
SCALE = (ENV["SCALE"] || "8").to_i

fib_n = 37
thread_workers = 4
thread_sum_total = 5_000_000 * SCALE

def fib_rec(k)
  return k if k < 2
  fib_rec(k - 1) + fib_rec(k - 2)
end

# Shared data
find_size = 200_000 * SCALE
find_iters = 50
find_target_start = 1
find_target_end = find_size
find_arr = (1..find_size).to_a

regex_str = ("abc123def" * (200_000 * SCALE))

suite = {}

suite["fib_rec"] = -> { fib_rec(fib_n) }

suite["array_sort"] = lambda do
  size = 200_000 * SCALE
  arr = Array.new(size) { rand(size) }
  arr.sort
end

suite["hash_count"] = lambda do
  count = 1_000_000 * SCALE
  h = Hash.new(0)
  count.times { |i| h[i % 10_000] += 1 }
  h
end

class KwInit
  def initialize(id:, name:, flags:)
    @id = id
    @name = name
    @flags = flags
  end
end

suite["class_new_kwargs"] = lambda do
  (200_000 * SCALE).times do |i|
    KwInit.new(id: i, name: "user#{i}", flags: [true, false, i % 2 == 0])
  end
end

suite["string_ivar_access"] = lambda do
  s = String.new("hello")
  (500_000 * SCALE).times do |i|
    s.instance_variable_set(:@v, i)
    s.instance_variable_get(:@v)
  end
end

klass = String
suite["class_hash"] = lambda do
  (5_000_000 * SCALE).times { klass.hash }
end

suite["class_object_id"] = lambda do
  (5_000_000 * SCALE).times { klass.object_id }
end

suite["array_find"] = lambda do
  find_iters.times { find_arr.find { |v| v == find_target_end } }
end

if find_arr.respond_to?(:rfind)
  suite["array_rfind"] = lambda do
    find_iters.times { find_arr.rfind { |v| v == find_target_start } }
  end
end

suite["array_rev_find"] = lambda do
  find_iters.times { find_arr.reverse_each.find { |v| v == find_target_start } }
end

suite["regex_scan"] = lambda do
  regex_str.scan(/\d+/)
end

suite["json_round"] = lambda do
  obj = { user: "taro", roles: %w[admin editor], flags: (1..(1000 * SCALE)).to_a }
  json = JSON.dump(obj)
  JSON.parse(json)
end

suite["thread_sum"] = lambda do
  slice = thread_sum_total / thread_workers
  threads = thread_workers.times.map do |t|
    start = (t * slice) + 1
    finish = (t == thread_workers - 1) ? thread_sum_total : (t + 1) * slice
    Thread.new do
      sum = 0
      i = start
      while i <= finish
        sum += i
        i += 1
      end
      sum
    end
  end
  threads.each(&:join)
end

if defined?(Ractor)
  suite["ractor_sum"] = lambda do
    slice = thread_sum_total / thread_workers
    ractors = thread_workers.times.map do |t|
      start = (t * slice) + 1
      finish = (t == thread_workers - 1) ? thread_sum_total : (t + 1) * slice
      Ractor.new(start, finish) do |s, f|
        sum = 0
        i = s
        while i <= f
          sum += i
          i += 1
        end
        sum
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
