Talker.UsernameAutocompleter = function(){
  var self = this;
  
  self.current_cycle_username = null;
  
  $('#msgbox').keydown(function(e){
    var caret_position = $('#msgbox').getCaretPosition();
    
    if (caret_position > 0 && $('#msgbox').val().substring(caret_position - 1, caret_position) == '@'){
      if (e.which == 9) { // tab
        var user = self.nextUserName(e.shiftKey); // shift key reverses cycling
        $('#msgbox').insertAtCaret(user);
        $('#msgbox').setCaretPosition(caret_position, caret_position + user.length + 1)
        e.preventDefault();
      }
      
      if (e.which == 32) { // space
        $('#msgbox').insertAtCaret($('#msgbox').getSelectedText() + ' ');
        e.preventDefault();
      }
    }
  });
  
  self.nextUserName = function(reverse) {
    var users = _.reject(Talker.getRoomUsernames(), function(user) {
      return user == Talker.currentUser.name;
    });
    
    users = (reverse ? users.reverse() : users );
    
    if (self.current_cycle_username == null || _.indexOf(users, self.current_cycle_username) == users.length - 1) {
      return self.current_cycle_username = users[0];
    } else {
      return self.current_cycle_username = users[_.indexOf(users, self.current_cycle_username) + 1];
    }
  };
}