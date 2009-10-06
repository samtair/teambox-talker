$(function() {
    $("#msgbox")
      .keydown(function(e) {
        if (e.which == 13) {
          ChatRoom.send(this.value, true);
          ChatRoom.newMessage();
          return false;
        }
      })
      .keyup(function(e) {
        ChatRoom.sendLater(this.value);
      });
    
    // reformat all messages loaded from db on first load
    $('.content').each(function(something, element){
      element.innerHTML = ChatRoom.formatMessage(this.innerHTML, true);
    });

    ChatRoom.newMessage();
});

var ChatRoom = {
  messages: {},
  currentMessage: null,
  maxImageWidth: 400,
  
  sendLater: function(data) {
    if (data === "") return;
    if (this.sendTimeout) clearTimeout(this.sendTimeout);
    this.sendTimeout = setTimeout(function() {
      ChatRoom.send(data);
    }, 400);
  },
  
  send: function(data, eol) {
    if (data === "") return;
    if (this.sendTimeout) clearTimeout(this.sendTimeout);

    console.info("sending message");
    var message = this.currentMessage;
    message.content = data;
    this.client.send({id: message.uuid, content: message.content, "final": (eol == true)});
  },
  
  scrollToBottom: function() {
    window.scrollTo(0, document.body.clientHeight);
  },
  
  newMessage: function() {
    if (this.currentMessage) this.currentMessage.createElement().insertBefore($("#message"));
    this.currentMessage = new Message(currentUser.name);
    this.messages[this.currentMessage.uuid] = this.currentMessage;
    
    // Move the new message form to the bottom
    $("#message").
      appendTo($("#log")).
      find("form").reset().
      find("textarea").focus();
    
    this.scrollToBottom();
  },
  
  formatMessage: function(content, noScroll) {
    var image = content.match(/^https?:\/\/[^\s]+\.(gif|png|jpeg|jpg)$/g);
    if (image){
      return content.replace(image, '<a href="' + image + '" target="_blank"><img src="' + image + '" onload="ChatRoom.resizeImage(this, true)" style="visibility: hidden;" /></a>');
    } else {
      return content;
    }
  },
  
  resizeImage: function(image, noScroll){
    $(image).css({width: 'auto'});
    if (image.width > ChatRoom.maxImageWidth){
      $(image).css({width: ChatRoom.maxImageWidth + 'px'});
    }
    image.style.visibility = 'visible';
    if (!noScroll) ChatRoom.scrollToBottom();
  },
  
  onNewMessage: function(data) {
    var message = ChatRoom.messages[data.id];
    if (!message) {
      message = ChatRoom.messages[data.id] = new Message(data.from, data.id);
      message.createElement();
    }
    
    if (data.final) {
      message.update(ChatRoom.formatMessage(data.content));
      message.element.removeClass('partial');
    } else {
      message.update(data.content);
    }
    
    if (!ChatRoom.typing()) {
      $("#message").
        appendTo($("#log")).
        find("textarea").focus();
    }

    ChatRoom.scrollToBottom();
  },
  
  typing: function() {
    return ChatRoom.currentMessage != null && ChatRoom.currentMessage.content != null
  },
  
  addUser: function(user) {
    if ($("ul#users li:contains('" + user.name + "')").length < 1){
      $('ul#users').append('<li>' + user.name + '</li>')
    }
    $("ul#users li:contains('" + user.name + "')").highlight();
  },
  
  addNotice: function(data){
    console.info(data);
    var msg_content = '';
    switch(data.type){
      case 'join': 
      case 'leave':
        msg_content = data.type + 's';
        break
      default:
        msg_content = data.type;
        break;
    }
    
    var element = $("<tr/>").
      addClass("event").
      addClass("notice").
      append($("<td/>").addClass("author").html(data.user)).
      append($("<td/>").addClass("content").html(data.type));
    
    if (ChatRoom.typing())
      element.appendTo("#log");
    else
      element.insertBefore("#message");
  },
  
  onJoin: function(data) {
    ChatRoom.addUser(data.user);
    if (data.type == "join") ChatRoom.addNotice(data);
  },

  onLeave: function(data) {
    $("ul#users li:contains('" + data.user + "')").remove();
    ChatRoom.addNotice(data);
  },
  
  onClose: function(){
    ChatRoom.addNotice({user:"System", type: "the persistent connection to talker is not active."});
  }
};

function Message(from, uuid) {
  this.from = from;
  this.uuid = uuid || Math.uuid();
  this.elementId = "message-" + this.uuid;
  
  this.update = function(content) {
    this.content = content;
    if (this.element) this.element.find(".content").html(content);
  }  
  
  this.createElement = function() {
    // Create of find the message HTML element
    this.element = $("#log").find("#" + this.elementId);
    if (this.element.length == 0) {
      this.element = $("<tr/>").
        addClass("event").
        addClass("message").
        addClass("partial").
        attr("id", this.elementId).
        append($("<td/>").addClass("author").html(this.from)).
        append($("<td/>").addClass("content").html(this.content || "")).
        appendTo($("#log"));
    }
    return this.element;
  }
}