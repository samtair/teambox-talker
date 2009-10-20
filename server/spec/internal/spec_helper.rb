require File.dirname(__FILE__) + "/../spec_helper"

class ReceiveEventMatcher
  def initialize(expected_msg)
    @expected_msg = expected_msg
  end
  
  def matches?(queue)
    @queue = queue
    Yajl::Parser.parse(queue.received_messages.join) == @expected_msg
  end
  
  def failure_message_for_should
    "expected #{@queue.name} to have received message #{@expected_msg.inspect}"
  end

  def failure_message_for_should_not
    "expected #{@queue.name} to not have received message #{@expected_msg.inspect}"
  end
end

module Helpers
  def encode(json)
    Yajl::Encoder.encode(json) + "\n"
  end

  def receive_event(expected_msg)
    ReceiveEventMatcher.new(expected_msg)
  end
end

Spec::Runner.configure do |config|
  config.include Helpers
end