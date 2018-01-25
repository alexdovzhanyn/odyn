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

# Merkle root lets us represet a large dataset using a SHA256 hash. We can be confident
# that if any of the pieces within the dataset change, the hash will change, and we can
# deem the dataset invalid
def calculate_merkle_root(array)
  unless array.length == 1
    array = calculate_merkle_root(array.each_slice(2).map{|a, b| Digest::SHA256.hexdigest(a.to_s + b.to_s)})
  end

  array
end

def parameterize(params)
  # Transforms a hash to a parameter string
  # E.x. {a: 'something', b: 'otherthing'} => 'a=something&b=otherthing'
  URI.escape(params.collect{|k,v| "#{k}=#{v}"}.join('&'))
end
