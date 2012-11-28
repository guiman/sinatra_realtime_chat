require_relative '../chat'
require 'rubygems'
require 'bundler/setup'
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'test/unit'

class CapybaraTestCase < Test::Unit::TestCase
  # including Capybara DSL magic
  include Capybara::DSL
  
  def setup
    # we will be using the PhantomJS driver to test our app. The other possible options are: Selenium or WebKit.
    Capybara.default_driver = :poltergeist
    Capybara.app = ChatApp
  end
  
  def teardown
    Capybara.reset_sessions!
  end
end