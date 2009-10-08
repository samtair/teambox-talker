// Talker client
// Based on STOMP client shipped with Orbited.
function TalkerClient(options) {
  var log = getTalkerLogger("TalkerClient");
  var self = this;
  var protocol = null;
  var buffer = "";
  var remainingBodyLength = null;
  self.options = options;

  // LineProtocol implementation.
  function onLineReceived(line) {
    var line = eval('(' + line + ')');
    
    console.info("TalkerClient::onLineReceived" + line);
    
    // ugly shit but this will be refactored.
    switch(line.type){
      case 'message':
        options.onNewMessage(line);
        break;
      case 'join':
        self.sendData({type: "present", to: line.user});
      case 'present':
        options.onJoin(line);
        break;
      case 'leave':
        options.onLeave(line);
        break;
      case 'error':
        alert("An unfortunate error occured.  At least no one got hurt. (" + line.message + ")");
        break;
    } 
  }
  
  function onRawDataReceived(data) {
    console.info("TalkerClient::received raw: " + data);
  }
  
  self.resetPing = function() {
    if (self.pingInterval) clearInterval(self.pingInterval);
    self.pingInterval = setInterval(function(){
      self.ping();
    }, 5000);
  };
  
  self.ping = function(){
    if (self.reconnect){
      location.reload();
    }else{
      protocol.send(JSON.encode({type: 'ping'}));
    }
  };
  
  // Methods
  self.sendData = function(message) {
    protocol.send(JSON.encode(message));
    self.resetPing();
  };

  self.connect = function() {
    protocol = new LineProtocol(new TCPSocket());
    protocol.onopen = function() {
      self.sendData({
        type: "connect", 
        room: self.options.room, 
        user: self.options.user, 
        token: self.options.token
      });
    }
    // XXX even though we are connecting to onclose, this never gets fired
    //     after we shutdown orbited.
    protocol.onclose = function() {
      self.reconnect = true;
      options.onClose();
    }
    // TODO what should we do when there is a protocol error?
    protocol.onerror = function(error) { console.error(error); }
    protocol.onlinereceived = onLineReceived;
    protocol.onrawdatareceived = onRawDataReceived;
    protocol.open(self.options.host, self.options.port, true);
  };

  self.close = function() {
    self.sendData({type: "close"});
  };
  self.reset = function() {
    protocol.reset();
  }
  self.send = function(message) {
    message.type = "message";
    self.sendData(message);
  };
}
