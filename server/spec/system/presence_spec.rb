require File.dirname(__FILE__) + "/spec_helper"

EM.describe "Talker client presence info" do
  it "should be broadcasted on join" do
    # User 1 will receive notification of join
    connect :room => "test", :user => {:id => 1, :name => "user1"} do |client|
      client.on_join do |user|
        user.id.should == 2
        user.name.should == "user2"
      end
    end
    
    # User 2 receives presence info
    connect :room => "test", :user => {:id => 2, :name => "user2"} do |client|
      client.on_presence do |user|
        user.id.should == 1
        user.name.should == "user1"
        client.close
      end
      
      client.on_close { done }
    end
  end

  it "should be broadcasted on close" do
    # User 1 will receive notification of leave
    connect :room => "test", :user => {:id => 1, :name => "user1"} do |client|
      client.on_leave do |user|
        user.id.should == 2
        client.close
      end

      client.on_close { done }
    end
    
    # User 2 just close the connection
    connect :room => "test", :user => {:id => 2, :name => "user2"} do |client|
      client.on_connected do
        client.close
      end
    end
  end
end