def async
  Thread.new do
    Thread.current.abort_on_exception = true
    yield
    Thread.current.kill
  end
end
