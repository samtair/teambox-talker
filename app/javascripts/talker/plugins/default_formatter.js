// this formatter is always called when others aren't called first.
Talker.DefaultFormatter = function() {
  var self = this;
  
  self.onFormatMessage = function(event){
    var url_expression = /(https?:\/\/|www\.)[^\s<]*/gi;
    var protocol_expression  = /^(http|https|ftp|ftps|ssh|irc|mms|file|about|mailto|xmpp):\/\//;
    
    var content = event.content.replace(/</g, '&lt;').replace(/>/g, '&gt;');
    
    if (content.match(url_expression)){
      event.complete(content.replace(url_expression, function(locator){
        return '<a href="' 
          +  (!locator.match(protocol_expression) ? 'http://' : '') + locator
          + '" target="_blank">' 
          +   locator 
          + "</a>";
      }));
    } else if (event.content.match(/\n/gim)){
      event.complete('<div><pre>' + content + '</pre></div>');
    } else {
      event.complete(content);
    }
  }
};