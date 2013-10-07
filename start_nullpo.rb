require 'socket'
require 'nkf'
require_relative 'irc_client'
require_relative 'nullpo_bot'
server = {
  host: '127.0.0.1',
  port: 6667,
  line_separator: "\r\n",
}
local = {
  user: 'nullpo-bot',
  host: IPSocket::getaddress(Socket::gethostname),
  server: IPSocket::getaddress(Socket::gethostname),
  realname: 'nullpo',
  nickname: 'nullpo-bot',
  password: 'your password',
}
channel = {
  name: '#channel',
}

client = IRCClient.new(TCPSocket.open(server[:host], server[:port]), server[:line_separator])
class << client
  def message(command, *params)
    puts '>> ' + IRCMessage.new(nil, command.to_s.upcase, params).to_s
    super
  end
end
begin
  client.pass local[:password]
  client.user local[:user], local[:host], local[:server], local[:realname]
  client.nick local[:nickname]
  client.join channel[:name]
  bot = NullpoBot.new(client)
  begin
    bot.start
  ensure
    bot.quit
  end
ensure
  client.close
end
