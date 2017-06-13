def print_memory_usage
  memory_before = `ps -o rss= -p #{Process.pid}`.to_i
  yield
  memory_after = `ps -o rss= -p #{Process.pid}`.to_i

  puts "Memory usage: #{((memory_after - memory_before) / 1024.0).round(3)} MB"
end

def print_time_spent
  time = Benchmark.realtime do
    yield
  end

  puts "Time spent: #{time.round(2)}"
end
