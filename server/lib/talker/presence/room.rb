module Talker
  module Presence
    class Room < EventChannel
      def initialize(name, persister, timeout)
        super(name)
        @users = {}
        @persister = persister
        @timeout = timeout
        @idle_timers = {}
      end
    
      def users
        @users.values
      end
    
      # Add a user w/o broadcasting presence
      def <<(user)
        @users[user.id] = user
      end
    
      def present?(user)
        return false if user.nil?
        @users.key?(user.id)
      end
    
      def join(user, time=Time.now.to_i)
        if present?(user)
          # Back from idle if already present in the room
          stop_idle_timer user
          publish :type => "back", :user => user.info, :time => time
          @persister.update(@name, user.id, "online")
        else
          # New user in room if not present
          publish :type => "join", :user => user.info, :time => time
          @persister.store(@name, user.id, "online")
          self << user
          # Send list of online users to new user
          publish_to user.id, :type => "users", :users => users.map { |u| u.info }
        end
      end
      
      def start_idle_timer(user)
        @idle_timers[user.id] = EventMachine::Timer.new(@timeout) do
          Talker.logger.debug {"#{user.name} has been idle for more then #{@timeout} sec, leaving room##{name}"}
          leave user
        end
      end
      
      def stop_idle_timer(user)
        user.online!
        if timer = @idle_timers.delete(user.id)
          timer.cancel
        end
      end
      
      def idle(user, time=Time.now.to_i)
        if present?(user)
          user.idle!
          publish :type => "idle", :user => user.info, :time => time
          @persister.update(@name, user.id, "idle")
          
          # If still idle after timeout, user leaves room
          start_idle_timer user
        end
      end
    
      def leave(user, time=Time.now.to_i)
        if present?(user)
          publish :type => "leave", :user => user.info, :time => time
          publish_to user.id, :type => "error", :message => "Connection closed"
          @persister.delete(@name, user.id)
          @users.delete(user.id)
        end
      end
    end
  end
end