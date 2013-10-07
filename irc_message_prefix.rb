class IRCMessagePrefix
  attr_reader :nickname, :user, :host
  def initialize(nickname, user, host)
    @nickname = nickname
    @user = user
    @host = host
  end
  def to_s
    (nickname ? nickname + '!' : '') + (user ? user + '@' : '') + (host || '')
  end
  class << self
    def parse(s)
      matches = s.match(/^((.*)\!)?((.*)@)?(.*)$/)
      new matches[2], matches[4], matches[5]
    end
  end
end
