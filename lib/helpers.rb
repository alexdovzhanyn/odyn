def async
  # Run a block on a new thread and kill the thread afterwards.
  # This ensures that any errors encountered in the thread get propogated to the rest
  # of the program
  Thread.new do
    Thread.current.abort_on_exception = true
    yield
    Thread.current.kill
  end
end

def calculate_merkle_root(array)
  unless array.length == 1
    array = calculate_merkle_root(array.each_slice(2).map{|a, b| Digest::SHA256.hexdigest(a.to_s + b.to_s)})
  end

  array
end
