require_relative 'irc_message'
class IRCClient
  def initialize(tcp_socket, line_separator = "\n")
    @tcp_socket = tcp_socket
    @line_separator = line_separator
  end
  def close
    @tcp_socket.close
  end
  def each_message(&block)
    @tcp_socket.each_line(@line_separator) {|line|
      message = IRCMessage.parse line.chomp
      yield message
    }
  end
  def message(command, *params)
    @tcp_socket.puts IRCMessage.new(nil, command.to_s.upcase, params)
  end
  def pass(password)
    message :pass, password
  end
  def user(user, host, server, realname)
    message :user, user, host, server, realname
  end
  def nick(nickname)
    message :nick, nickname
  end
  def join(channel)
    message :join, channel
  end
  def pong(receiver)
    message :pong, receiver
  end
  def privmsg(receiver, body)
    message :privmsg, receiver, ':' + body
  end
  def quit(quit_message)
    message :quit, ':' + quit_message
  end
end
