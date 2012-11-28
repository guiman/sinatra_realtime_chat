require_relative 'test_helper'

class AppTest < CapybaraTestCase
  def test_sign_in_with_an_available_user
    # let's get the main login page
    visit '/'

    # complete login form fields
    fill_in 'username', with: 'user'

    # click the submit button
    find_button("Log in").trigger('click')

    # find the current logged in user link. If it doesn't exists then we couldn't get in
    page.has_link? 'user'
    
    # check if the logout link is present and visible
    assert page.find_link('Logout').visible?
    
    # click the logout button
    click_link 'Logout'
  end
  
  def test_sign_in_with_a_non_available_user
    # create a user with username 'user'
    user = User.create(username: 'user')
    
    # let's get the main login page
    visit '/'

    # complete login form fields
    fill_in 'username', with: 'user'

    # click the submit button
    find_button("Log in").trigger('click')
    
    page.has_selector? '.alert', text: 'Sorry, user already taken or invalid. Try using other or wait until he/she leaves, your choice'
    
    # create a user with username 'user'
    user.destroy
  end
end

