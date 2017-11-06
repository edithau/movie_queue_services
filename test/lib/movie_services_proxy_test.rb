require 'test_helper'

class MovieServicesProxyTest < ActiveSupport::TestCase

  test '.check_ids - ids are valid' do

    MovieServicesProxy.stubs(:get).returns(  {
                                                 "id": "1",
                                                 "name": "Tropic Thunder",
                                                 "year": "2008",
                                                 "genre": "Comedy"
                                             })

    assert_equal([], MovieServicesProxy.check_ids(['1']),
                 'should have returned an empty array since the id is valid')
  end


  test '.check_ids - ids are not valid' do
    MovieServicesProxy.stubs(:get).returns( [])
    MovieServicesProxy.stubs(:get_from_source).returns([])


    assert MovieServicesProxy.check_ids(['invalid_id']) == ['invalid_id'],
           'should have returned an array with the invalid id'
  end

  test '.prepopulate' do
    assert (MovieServicesProxy.prepopulate File.join(Rails.root, 'data', 'movies.json')).size > 0,
           'should have pre-populated redis with movie records'

  end
end
