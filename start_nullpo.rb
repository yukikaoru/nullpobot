require 'yaml'
require 'socket'
require 'nkf'
require_relative 'irc_client'
require_relative 'nullpo_bot'

def _symbolize_keys(value)
  case value
  when Hash
    value.reduce({}) {|result, (key, value)|
      result.merge({key.is_a?(String) ? key.to_sym : key => _symbolize_keys(value)})
    }
  when Enumerable
    value.map {|element| _symbolize_keys(element)}
  else
    value
  end
end

def symbolize_keys(hash)
  _symbolize_keys(hash)
end

defaults = {
  server: {
    host: '127.0.0.1',
    port: 6667,
    line_separator: "\r\n",
  },
  local: {
    user: 'nullpo-bot',
    host: IPSocket::getaddress(Socket::gethostname),
    server: IPSocket::getaddress(Socket::gethostname),
    realname: 'nullpo-bot',
    nickname: 'nullpo-bot',
    password: 'your password',
  },
  channel: {
    name: '#channel',
  }
}

config_file = File.dirname(__FILE__) + '/config.yaml'
config = symbolize_keys(YAML::load(File.read(config_file)))
[:server, :local, :channel].each {|key|
  config[key] = config[key] ? defaults[key].merge(config[key]) : defaults[key]
}

client = IRCClient.new(TCPSocket.open(config[:server][:host], config[:server][:port]), config[:server][:line_separator])

class << client
  def message(command, *params)
    puts '>> ' + IRCMessage.new(nil, command.to_s.upcase, params).to_s
    super
  end
end

begin
  client.pass config[:local][:password]
  client.user config[:local][:user], config[:local][:host], config[:local][:server], config[:local][:realname]
  client.nick config[:local][:nickname]
  client.join config[:channel][:name]
  bot = NullpoBot.new(client)
  begin
    bot.start
  ensure
    bot.quit
  end
ensure
  client.close
end
