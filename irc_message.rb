require_relative 'irc_message_prefix'
class IRCMessage
  attr_reader :prefix, :command, :params
  def initialize(prefix, command, params)
    @prefix = prefix
    @command = command
    @params = params
  end
  def to_s
    ((prefix ? [':' + prefix.to_s] : []) + [command, *params]).join(' ')
  end
  class << self
    def split_params(line)
      if line.empty?
        []
      elsif line[0] == ':'
        [line]
      else
        matches = line.match(/^([^ ]+) *(.*)/)
        [matches[1]] + split_params(matches[2])
      end
    end
    def parse(line)
      matches = line.match(/^(\:([^ ]+))? *([^ ]*) *(.*)$/)
      new(matches[2] && IRCMessagePrefix.parse(matches[2]), matches[3], split_params(matches[4]))
    end
  end
end
