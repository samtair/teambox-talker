require File.dirname(__FILE__) + "/../test_helper"

class InvitesControllerTest < ActionController::TestCase
  def setup
    subdomain :master
  end
  
  def test_index
    login_as :quentin
    get :index
    assert_response :success
  end
  
  def test_show_with_invalid_token
    get :show, :id => "uho!"
    assert_not_nil flash[:error]
    assert_redirected_to login_path
  end
  
  def test_show_pending_user
    users(:quentin).update_attribute :state, "pending"
    users(:quentin).create_perishable_token!
    
    get :show, :id => users(:quentin).perishable_token
    assert_nil flash[:error]
    assert_template :show
    assert_response :success, @response.body
  end

  def test_show_active_user
    users(:quentin).update_attribute :state, "active"
    users(:quentin).create_perishable_token!
    
    get :show, :id => users(:quentin).perishable_token
    assert_nil flash[:error]
    assert_nil flash[:notice]
    assert_redirected_to rooms_path
  end
  
  def test_show_active_user_to_room
    users(:quentin).update_attribute :state, "active"
    users(:quentin).create_perishable_token!
    
    get :show, :id => users(:quentin).perishable_token, :room => Room.first
    assert_redirected_to Room.first
  end
  
  def test_set_password
    login_as :quentin
    put :set_password, :user => hash_for_user
    assert_redirected_to rooms_path
  end
  
  def test_set_password_to_room
    login_as :quentin
    put :set_password, :user => hash_for_user, :room_id => Room.first.id
    assert_redirected_to Room.first
  end
  
  def test_create
    login_as :quentin
    assert_difference 'User.count', 2 do
      assert_difference 'ActionMailer::Base.deliveries.size', 2 do
        post :create, :invitees => "one@example.com\ntwo@example.com", :room_id => Room.first
        assert_nil flash[:error]
        assert_equal %w(one@example.com two@example.com), assigns(:invitees)
      end
    end
    assert_redirected_to users_path
  end
  
  def test_create_with_coma
    login_as :quentin
    assert_difference 'User.count', 2 do
      assert_difference 'ActionMailer::Base.deliveries.size', 2 do
        post :create, :invitees => "one@example.com, two@example.com", :room_id => Room.first
        assert_nil flash[:error]
        assert_equal %w(one@example.com two@example.com), assigns(:invitees)
      end
    end
    assert_redirected_to users_path
  end
  
  def test_create_with_invite_command
    login_as :quentin
    assert_difference 'User.count', 1 do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        xhr :post, :create, :invitees => "one@example.com", :room_id => Room.first
        assert_nil flash[:error]
        assert_equal %w(one@example.com), assigns(:invitees)
      end
    end
    assert_response :success
  end
  
  def test_create_with_invite_command_but_improper_email
    login_as :quentin
    xhr :post, :create, :invitees => "asdfasdf", :room_id => Room.first
    assert_template "error"
    assert_response :success
  end
  
  def test_create_with_invalid_email
    login_as :quentin
    assert_difference 'User.count', 1 do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        post :create, :invitees => "one@example.com\nblablabla", :room_id => Room.first
        assert_not_nil flash[:error]
      end
    end
    assert_redirected_to users_path
  end

  def test_create_with_existing_email
    login_as :quentin
    aaron = create_user(:email => 'aaron@example.com')
    assert_difference 'User.count', 0 do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        post :create, :invitees => "aaron@example.com", :room_id => Room.first
        assert_nil flash[:error]
      end
    end
    aaron = User.find_by_email('aaron@example.com')
    assert_equal true, aaron.permissions.map(&:room).include? (Room.first)
    assert_redirected_to users_path
  end
  
  def test_resend
    login_as :quentin
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      post :resend, :id => users(:quentin), :room_id => Room.first
    end
    assert_redirected_to users_path
  end
end
