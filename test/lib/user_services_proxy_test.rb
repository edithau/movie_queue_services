require 'test_helper'

class UserServicesProxyTest < ActiveSupport::TestCase


  test '#prepopulate' do
    assert (UserServicesProxy.prepopulate File.join(Rails.root, 'data', 'users.json')).size > 0,
           'should have pre-populated redis with user records'

  end
end
