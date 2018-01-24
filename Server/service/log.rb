require "#{ROOT}/service/time.rb"

begin
    `mkdir #{ROOT}/log`
rescue
end
`echo > #{ROOT}/log/errors.txt`
begin
    `echo > #{ROOT}/log/activities.log` if File.read("#{ROOT}/log/activities.log").split("\n").size >= 1000
rescue
    `echo > #{ROOT}/log/activities.log`
end

$log = []

at_exit do
    File.open("#{ROOT}/log/old.log", 'a') { |file| file.write($log.join("\n")) }
end

def LOG(msg, method = "none", _time = true)
    case method
    when 'DEBUG'
        destination = "#{ROOT}/log/debug.log"
    when "SnapController"
        destination = "#{ROOT}/log/snapshot.log"
    else
        destination = "#{ROOT}/log/activities.log"
    end
    msg = msg.to_s
    msg = "[ #{time(method)} ] " + msg if _time
    msg += " [ #{method} ]" if method != 'none' && method != "" && method != nil

    File.open(destination, 'a'){ |log| log.write msg + "\n" }

    $log << "#{msg} | #{destination}"
    puts "Should be logged, params - #{method}, #{_time}, #{destination}:\n#{msg}" if DEBUG
    return true
end