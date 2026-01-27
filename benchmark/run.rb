# frozen_string_literal: true

require "benchmark"
require "json"

RESULTS = []

Benchmark.bm(20) do |x|
  n = 35
  x.report("fib_rec") do
    def fib_rec(k)
      return k if k < 2
      fib_rec(k - 1) + fib_rec(k - 2)
    end
    fib_rec(n)
  end

  size = 200_000
  x.report("array_sort") do
    arr = Array.new(size) { rand(size) }
    arr.sort
  end

  count = 1_000_000
  x.report("hash_count") do
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

  x.report("class_new_kwargs") do
    200_000.times do |i|
      KwInit.new(id: i, name: "user#{i}", flags: [true, false, i % 2 == 0])
    end
  end

  x.report("string_ivar_access") do
    s = String.new("hello")
    500_000.times do |i|
      s.instance_variable_set(:@v, i)
      s.instance_variable_get(:@v)
    end
  end

  klass = String
  x.report("class_hash") do
    5_000_000.times { klass.hash }
  end

  x.report("class_object_id") do
    5_000_000.times { klass.object_id }
  end

  find_size = 200_000
  find_iters = 200
  find_target_start = 1
  find_target_end = find_size
  find_arr = (1..find_size).to_a
  x.report("array_find") do
    find_iters.times { find_arr.find { |v| v == find_target_end } }
  end

  if find_arr.respond_to?(:rfind)
    x.report("array_rfind") do
      find_iters.times { find_arr.rfind { |v| v == find_target_start } }
    end
  end

  x.report("array_rev_find") do
    find_iters.times { find_arr.reverse_each.find { |v| v == find_target_start } }
  end

  x.report("regex_scan") do
    str = ("abc123def" * 200_000)
    str.scan(/\d+/)
  end

  x.report("json_round") do
    obj = { user: "taro", roles: %w[admin editor], flags: (1..1000).to_a }
    json = JSON.dump(obj)
    JSON.parse(json)
  end
end
