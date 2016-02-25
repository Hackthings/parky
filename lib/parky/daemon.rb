class Parky::Daemon

  def initialize(config, slackbot)
    @config = config
    @slackbot = slackbot
    @active = true
    @running = false
  end

  def start(daemonize = true)
    Process.daemon if daemonize
    write_pid

    [ 'HUP', 'INT', 'QUIT', 'TERM' ].each do |sig|
      Signal.trap(sig) do
        @config.log "Interrupted with signal: #{sig}"
        kill
      end
    end

    begin
      @slackthread = Thread.new { @slackbot.run }
      run
    rescue => e
      @config.log "Unexpected error", e
    ensure
      cleanup
    end
  end

  def cleanup
    delete_pid
  end

  private

  def run
    @config.log "Parky is running."
    while active? do
      sleep 0.5
    end
    @config.log "Parky got killed"
    @slackthread.kill
  end

  def active?
    @active
  end

  def kill
    @active = false
  end

  def write_pid
    File.open @config.pid_file, 'w' do |f|
      f.write Process.pid.to_s
    end
  end

  def delete_pid
    File.delete @config.pid_file if File.exists? @config.pid_file
  end
end