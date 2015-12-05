
module ThorHelpers
  # http://apidock.com/rails/v4.2.1/Kernel/capture
  def capture(stream)
    stream = stream.to_s
    captured_stream = Tempfile.new(stream)
    stream_io = eval("$#{stream}")
    origin_stream = stream_io.dup
    stream_io.reopen(captured_stream)

    yield

    stream_io.rewind
    return captured_stream.read
  ensure
    captured_stream.close
    captured_stream.unlink
    stream_io.reopen(origin_stream)
  end
end

RSpec.configure do |config|
  config.around :each do |example|
    Dir.mktmpdir {|dir|
      @current_dir = dir
      example.run
    }
  end
  config.include ThorHelpers
end
