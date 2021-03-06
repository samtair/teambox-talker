require "moqueue"

# Patch moqueue for some missing methods
module Moqueue
  class MockQueue
    def subscribed?
      !!@subscribe_block
    end
    
    def delete
      # noop
    end

    def reset
      # noop
    end
    
    def unsubscribe
      @subscribe_block = nil
    end
  end
  
  class MockExchange
    def name
      @topic || @fanout || @direct
    end
  end
end

overload_amqp

class MQ
  class << self
    def queue(name, opts={})
      Moqueue::MockQueue.new(name)
    end
    
    def topic(name, opts={})
      Moqueue::MockExchange.new(opts.merge(:topic=>name))
    end
  end
end

Spec::Runner.configure do |config|
  config.before do
    Moqueue::MockBroker.instance.reset!
    Talker::Server::Queues.reset!
  end
end