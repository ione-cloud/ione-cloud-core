require 'rubygems'
require 'zmqjsonrpc'
require 'nori'

client = ZmqJsonRpc::Client.new("tcp://185.66.68.238:8008")

puts client.test()