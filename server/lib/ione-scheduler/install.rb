require 'mysql2'
require 'yaml'

ROOT = ENV['IONEROOT'] # IONe root path
CONF = YAML.load(File.read("#{ROOT}/config.yml")) # IONe configuration constants

print 'Connecting to DB server...'
begin
client = Mysql2::Client.new(
    :username => CONF['DataBase']['user'], :password => CONF['DataBase']['pass'], 
    :host => CONF['DataBase']['host'] )
    puts ' [ OK ]'
rescue => e
    puts " [ Error ] \n Error: #{e.message}"
    Kernel.exit
end

print 'Creating DB ioneschedule...'
begin
    client.query('CREATE DATABASE ioneschedule')
    puts ' [ OK ]'
rescue => e
    puts " [ Error ] \n Error: #{e.message}"
end

print 'Connecting to ioneschedule DB...'
begin
    client = Mysql2::Client.new(
        :username => CONF['DataBase']['user'], :password => CONF['DataBase']['pass'], 
        :host => CONF['DataBase']['host'], :database => 'ioneschedule' )
        puts ' [ OK ]'
rescue => e
    puts " [ Error ] \n Error: #{e.message}"
end

print 'Creating actions table...'
begin
    client.query(
        'CREATE TABLE action (
            class VARCHAR(20), method VARCHAR(20),
            params VARCHAR(20), time INT,
            id INT NOT NULL AUTO_INCREMENT,
            PRIMARY KEY (id)
        )'
    )
    puts ' [ OK ]'
rescue => e
    puts " [ Error ] \n Error: #{e.message}"
end