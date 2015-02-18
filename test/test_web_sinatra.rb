require_relative 'init'
require 'rack/test'
require_relative '../web/application'


class TestWebSinatra < Minitest::Test
  include Rack::Test::Methods

  def setup
    Pcaper::Config.load_hash(TESTBED_CONFIG) unless Pcaper::Config.loaded?
    create_pcaps_db(fixture_join('skel/fully_populated.sql'))
    create_web_db
  end

  def set_last_error_response
    return "" if last_response.ok?
    caller_bt = caller.grep(/`test_/)[0]
    return "" unless caller_bt
    caller_meth = caller_bt.scan(/`(\S+)'/).flatten.first
    body_file = "#{pcaper_home}/test/fixtures/tmp/#{caller_meth}.html"
    File.open(body_file, 'w'){|fh| fh.print last_response.body}
    title = last_response.body.scan(/<title>(.*)<\/title>/i).flatten.first
    msg = "html-title: '#{title}', Full response -> #{body_file.gsub(/#{pcaper_home}\//, '')}"
    return msg
  end

  def app
    Sinatra::Application
  end

  #
  # pre-flight check
  #
  def test_that_webdb_are_valid_and_empty
    assert Pcaper::Config.webdb, "webdb is undefined"
    assert_equal [:carve], Pcaper::Config.webdb.tables
    assert_equal 0, Pcaper::Config.webdb[:carve].count
  end

  #
  # GET /
  #
  def test_root_should_redirect_to_find
    get '/'
    assert last_response.redirect?
    assert_equal "http://example.org/find", last_response.location
  end

  #
  # GET /find
  #
  def test_find_without_args
    get '/find'
    assert last_response.ok?, set_last_error_response
  end

  def test_find_without_all_required_args
    get '/find', 
      :start_time => '2013-12-01 11:15:26 +0100'
    assert last_response.ok?, set_last_error_response
    assert last_response.body.include?("All required fields (start_time, src, dst) must be set")
  end

  def test_find_will_find_the_session
    get '/find',
      :start_time => '2013-12-01 11:15:26 +0100',
      :src    => '192.168.0.1',
      :sport  => '35594',
      :dst    => '192.168.0.2',
      :dport  => '22',
      :proto  => 'tcp'
    assert last_response.ok?, set_last_error_response
    assert last_response.body.include?("SSH-2.0-OpenSSH_5.9p1")
    assert last_response.body.include?("SSH-1.99-OpenSSH_3.9p1")
  end

  def test_find_should_handle_not_found
    get '/find',
      :start_time => '2013-12-01 11:15:26 +0100',
      :src    => '192.168.0.1',
      :sport  => '12345',
      :dst    => '192.168.0.2',
      :dport  => '12345',
      :proto  => 'tcp'
    assert last_response.ok?, set_last_error_response
    assert last_response.body.include?("No sessions found")
  end

  #
  # GET /carve
  #
  def test_carve_should_put_a_carver_job_into_webdb
    assert_equal 0, Pcaper::Config.webdb[:carve].count
    get '/carve',
      :start_time => '2013-12-01 11:15:26 +0100',
      :src    => '192.168.0.1',
      :sport  => '35594',
      :dst    => '192.168.0.2',
      :dport  => '22',
      :proto  => 'tcp'
    assert last_response.ok?, set_last_error_response
    assert_equal 1, Pcaper::Config.webdb[:carve].count, "webdb should have a carve job submitted"
    assert_equal 'submitted', Pcaper::Config.webdb[:carve].first[:worker_state], "webdb :worker_state != submitted"
  end

  def test_carve_should_not_put_invalid_carver_job_into_webdb
    assert_equal 0, Pcaper::Config.webdb[:carve].count
    get '/carve',
      :start_time => '2013-12-01 11:15:26 +0100',
      :src    => '192.168.0.1',
      :dst    => '<script>alert("test");</script>'
    assert last_response.ok?, set_last_error_response
    assert_equal 0, Pcaper::Config.webdb[:carve].count, "carve record made it into db"
    assert last_response.body.include?('ArgumentError'), "no ArgumentError was found"
    refute last_response.body.include?('<script>'), "<script> tag was found"
  end

  def test_carve_should_tell_if_no_sessions_where_found
    assert_equal 0, Pcaper::Config.webdb[:carve].count
    get '/carve',
      :start_time => '2013-12-01 11:15:26 +0100',
      :src    => '192.168.0.1',
      :dst    => '1.1.1.1'
    assert last_response.ok?, set_last_error_response
    assert_equal 0, Pcaper::Config.webdb[:carve].count, "carve record made it into db"
    assert last_response.body.include?("no sessions where found")
  end

  #
  # GET /download/:chksum
  #
  def test_download_should_tell_if_no_record_was_found
    get "/download/1234"

    assert_equal 404, last_response.status, set_last_error_response
  end

  def test_download_should_download_file
    create_web_db(fixture_join('skel/webdb_processed_record.sql'))
    local_file = Pcaper::Config.webdb[:carve].first[:local_file]
    local_file_content = "This testfile pretends to be a pcap. Generated @#{Time.now}"
    File.open(local_file, 'w'){|fh| fh.print(local_file_content)}

    get "/download/431182551"

    assert last_response.ok?, set_last_error_response
    assert_equal 'application/vnd.tcpdump.pcap', last_response.header['Content-Type']
    assert_equal local_file_content, last_response.body
    assert_equal local_file_content.length, last_response.header['Content-Length'].to_i
  end

  def test_download_should_only_download_records_with_state_done
    create_web_db(fixture_join('skel/webdb_submitted_record.sql'))
    local_file = Pcaper::Config.webdb[:carve].first[:local_file]
    local_file_content = "This testfile pretends to be a pcap. Generated @#{Time.now}"
    File.open(local_file, 'w'){|fh| fh.print(local_file_content)}

    get "/download/431182551"

    refute_equal local_file_content, last_response.body
    assert_equal 404, last_response.status
  end
end

