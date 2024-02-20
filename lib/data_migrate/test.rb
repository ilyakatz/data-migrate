module Base
  extend self

  def foo
    puts "Base#foo called"
  end
end

module Child
  extend Base
  extend self

  puts "foo: #{respond_to?(:foo)}"
end
