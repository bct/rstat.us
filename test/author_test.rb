require_relative "test_helper"

class AuthorTest < MiniTest::Unit::TestCase

  include TestHelper

  def setup
    @author = Factory.build :author, :username => "james", :email => nil, :image_url => nil
  end

  def test_create_from_hash
    hash = {"user_info" => {"name" => "james", "nickname" => "jim", "urls" => {}} }
    assert Author.create_from_hash!(hash).is_a?(Author)
  end

  def test_url
    @author.remote_url = "some_url.com"
    assert_equal @author.remote_url, @author.url
  end

  def test_valid_avatar_url
    @author.email = "jamecook@gmail.com"

    VCR.use_cassette('fetch_valid_gravatar') do
      gravatar_url = @author.gravatar_url
      assert_equal gravatar_url, @author.avatar_url
    end
  end

  def test_invalid_avatar_url
    VCR.use_cassette('fetch_invalid_gravatar') do
      @author.email = "completely@invalid-email.asdfasd.com"
      assert_equal "/images/avatar.png", @author.avatar_url
    end
  end

  def test_avatar_url_memoization
    # without an email address, no gravatar can be found
    refute @author.valid_gravatar?

    @author.email = "jamecook@gmail.com"

    # here we check to see if the gravatar exists
    VCR.use_cassette('fetch_valid_gravatar') do
      assert @author.valid_gravatar?
    end

    # at this point the result should be cached, no further requests should be made
    assert @author.valid_gravatar?

    # but if we change the email address...
    @author.email = "completely@invalid-email.asdfasd.com"
    @author.save
    @author.reload

    # another request is made
    VCR.use_cassette('fetch_valid_gravatar') do
      refute @author.valid_gravatar?
    end

    # (just once)
    refute @author.valid_gravatar?
  end
end
