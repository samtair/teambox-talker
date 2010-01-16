require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  def test_should_create_user
    user = create_user
    assert user.valid?, user.errors.full_messages.to_sentence
    assert user.pending?
  end
  
  def test_name_validation
    assert_nil create_user(:name => "ma").errors.on(:name)
    assert_nil create_user(:name => "ma@ossum").errors.on(:name)
    assert_nil create_user(:name => "ma.n_i-ce").errors.on(:name)
    assert_nil create_user(:name => "Marc-André").errors.on(:name)
    assert_not_nil create_user(:name => "").errors.on(:name)
    assert_not_nil create_user(:name => "ma dude").errors.on(:name)
  end
  
  def test_generate_name
    user = build_user(:email => "ma@gmail.com")
    user.generate_name
    user.save!
    assert_equal "ma", user.name
    
    user = build_user(:email => "ma@hotmail.com")
    user.generate_name
    user.save!
    assert_equal "ma_1", user.name
    
    user = build_user(:email => "ma@yahoo.com")
    user.generate_name
    user.save!
    assert_equal "ma_2", user.name
  end
  
  def test_generate_name_without_email
    user = build_user(:email => nil)
    user.guest = true
    user.generate_name
    user.save!
    assert_equal "user", user.name
    
    user = build_user(:email => nil)
    user.guest = true
    user.generate_name
    user.save!
    assert_equal "user_1", user.name
  end

  def test_activating_should_set_timestamp
    user = create_user
    user.activate!
    assert user.active?
    assert_not_nil user.activated_at
  end

  def test_should_reset_password
    users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:quentin), User.authenticate('quentin@example.com', 'new password')
  end

  def test_should_not_update_to_blank_password
    users(:quentin).update_attributes(:password => '', :password_confirmation => '')
    assert_equal users(:quentin), User.authenticate('quentin@example.com', 'monkey')
  end

  def test_should_not_rehash_password
    users(:quentin).update_attributes(:email => 'quentin2@example.com')
    assert_equal users(:quentin), User.authenticate('quentin2@example.com', 'monkey')
  end

  def test_should_authenticate_user_by_email
    assert_equal users(:quentin), User.authenticate('quentin@example.com', 'monkey')
  end

  def test_should_authenticate_user_by_name
    assert_equal users(:quentin), User.authenticate('quentin', 'monkey')
  end

  def test_should_not_authenticate_suspended_user
    users(:quentin).suspend!
    assert_nil User.authenticate('quentin@example.com', 'monkey')
  end

  def test_should_authenticate_by_perishable_token
    users(:quentin).create_perishable_token!
    assert_equal users(:quentin), User.authenticate_by_perishable_token(users(:quentin).perishable_token)
  end

  def test_should_fail_authenticate_by_nil_perishable_token
    assert_not_nil users(:quentin), User.authenticate_by_perishable_token(nil)
  end

  def test_should_fail_authenticate_by_bad_perishable_token
    assert_not_nil users(:quentin), User.authenticate_by_perishable_token("ohaie")
  end

  def test_should_set_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
  end

  def test_should_unset_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    users(:quentin).forget_me
    assert_nil users(:quentin).remember_token
  end

  def test_create_talker_tokens
    assert_not_nil create_user.talker_token
  end
  
  def test_guest_have_permission_to_room
    assert_difference "Permission.count", 1 do
      create_user(:guest => true, :room => rooms(:main))
    end
  end
  
  def test_delete_unconnected_guest_user_with_same_name
    user = create_user(:name => "bob", :guest => true, :room => rooms(:main))
    
    assert create_user(:name => "bob", :room => rooms(:main)).valid?
    assert ! User.exists?(user.id)
  end

  def test_do_not_delete_connected_guest_user_with_same_name
    user = create_user(:name => "bob", :guest => true, :room => rooms(:main))
    user.connections.create :channel => rooms(:main)
    
    assert_not_nil create_user(:name => "bob", :room => rooms(:main)).errors.on(:name)
    assert User.exists?(user.id)
  end
  
  def test_color_validation
    assert_not_nil User.create(:color => "alert('hi')").errors.on(:color)
    assert_not_nil User.create(:color => "boom").errors.on(:color)
    assert_not_nil User.create(:color => "red").errors.on(:color)
    assert_nil User.create(:color => "#ccaabb").errors.on(:color)
    assert_nil User.create(:color => "#CCAABB").errors.on(:color)
    assert_nil User.create(:color => "#123456").errors.on(:color)
    assert_nil User.create.errors.on(:color)
  end
end
