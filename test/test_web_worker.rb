require_relative 'init'
require_relative '../web/bin/worker'


class TestWebWorker < Minitest::Test

  def setup
    Pcaper::Config.load_hash(TESTBED_CONFIG) unless Pcaper::Config.loaded?
    create_pcaps_db(fixture_join('skel/fully_populated.sql'))
    create_web_db(fixture_join('skel/webdb_submitted_record.sql'))
  end

  def test_that_worker_can_create_file
    assert_equal "submitted", Pcaper::Config.webdb[:carve].first[:worker_state], "need a sumitted record"
    worker_logfile = fixture_join('tmp/web_worker.log')
    FileUtils.rm_f(worker_logfile)
    FileUtils.rm_f(Pcaper::Config.webdb[:carve].first[:local_file])

    stderr = capture_output { Worker.run(Logger.new(worker_logfile)) }

    assert_equal "done", Pcaper::Config.webdb[:carve].first[:worker_state], "check worker logfile: #{worker_logfile}"
    assert_equal ["dump_00002_", "dump_00003_", "dump_00004_", "dump_00005_"], stderr.scan(/dump_\d+_/)
    capinfo = Pcaper::Capinfo.capinfo(Pcaper::Config.webdb[:carve].first[:local_file])
    assert_equal 32, capinfo[:num_packets], "checking number of packets..."
  end
end
