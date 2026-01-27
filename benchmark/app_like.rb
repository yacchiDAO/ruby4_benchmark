# frozen_string_literal: true

require "benchmark"
require "csv"
require "erb"
require "json"
require "stringio"

Benchmark.bm(20) do |x|
  x.report("erb_render") do
    template = ERB.new("<ul><% items.each do |item| %><li><%= item %></li><% end %></ul>")
    items = (1..200).map { |i| "item-#{i}" }
    300.times { template.result_with_hash(items: items) }
  end

  x.report("json_large") do
    data = (1..1000).map do |i|
      { id: i, name: "user#{i}", roles: ["user", "editor"], flags: (1..20).to_a }
    end
    json = JSON.dump(data)
    JSON.parse(json)
  end

  x.report("csv_generate") do
    rows = (1..5000).map { |i| [i, "name#{i}", i % 5, "2026-01-25"] }
    CSV.generate do |csv|
      rows.each { |row| csv << row }
    end
  end

  x.report("stringio_build") do
    io = StringIO.new
    100_000.times { |i| io << "line" << i.to_s << "\n" }
    io.string
  end

  x.report("router_sim") do
    routes = { "/" => "home", "/users" => "users", "/users/:id" => "user" }
    100_000.times do |i|
      path = (i % 2).zero? ? "/users/#{i}" : "/"
      if path.start_with?("/users/")
        routes["/users/:id"]
      else
        routes[path]
      end
    end
  end
end
