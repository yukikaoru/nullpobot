# encoding: utf-8
require 'nkf'
require 'json'
require 'rexml/document'
require 'open-uri'
require 'uri'

class Array
  def pick_random
    self[rand(self.length)]
  end
end

class Numeric
  def percent_do
    yield if rand * 100 < self
  end
end

def weekdays
  {
    :sunday => {:key => :sunday, :kanji => '日', :hiragana => 'にち'},
    :monday => {:key => :monday, :kanji => '月', :hiragana => 'げつ'},
    :tuesday => {:key => :tuesday, :kanji => '火', :hiragana => 'か'},
    :wednesday => {:key => :wednesday, :kanji => '水', :hiragana => 'すい'},
    :thursday => {:key => :thursday, :kanji => '木', :hiragana => 'もく'},
    :friday => {:key => :friday, :kanji => '金', :hiragana => 'きん'},
    :saturday => {:key => :saturday, :kanji => '土', :hiragana => 'ど'}
  }
end

module Nullporter
  class << self
    def hatena_haiku(keyword, star_limit)
      5.times.reduce(nil) {|result, n|
        result || begin
          url = 'http://h.hatena.ne.jp/api/statuses/keyword_timeline.json?word=' + URI.encode(keyword) + '&page=' + (rand(15) + 1).to_s + '&count=20'
          open(url) {|io|
            status = JSON::Parser.new(io.read).parse.select {|status| status['favorited'].to_i >= star_limit}.pick_random
            status && status['text'].gsub(/^.+?=/, '')
          }
        end
      }
    end
    def dajare
      begin
        hatena_haiku('ダジャレ', 3) || '404 Neta Not Found.'
      rescue
        p $!
        '偉いエラーです＞＜;'
      end
    end
    def weather_items
      url = 'http://tenki.jp/component/static_api/rss/forecast/city_63.xml'
      document = REXML::Document.new(open(url))
      document.get_elements('/rss/channel/item')
    end
    def parse_weather(item)
      title = item.get_elements('title').first.get_text.to_s
      return nil unless title
      match = /^.+\((.+)\)\s+(.+)\s+(.+)\/(.+)$/.match(title)
      return nil unless match
      {
        :weekday => match[1],
        :telop => match[2],
        :max_temperature => match[3],
        :min_temperature => match[4]
      }
    end
    def weather(offset_days)
      item = weather_items[offset_days]
      return nil unless item
      parse_weather(item)
    end
    def weather_of_next_weekday(weekday)
      weather_items.drop(1).map {|item| parse_weather(item)}.find {|weather| weather[:weekday] == weekdays[weekday][:kanji]}
    end
    def tepco
      url = 'http://tepco-usage-api.appspot.com/latest.json'
      JSON::Parser.new(open(url).read).parse
    end
  end
end
module NullpoBrain
  class << self
    def weather(body)
      data = nil
      match = /(次|つぎ|今度|こんど)の(月|火|水|木|金|土|日|げつ|か|すい|もく|きん|ど|にち)(曜|よう)(日|び)?の(天気|てんき)/.match(body)
      if match
        matched_weekday = match[2]
        weekday = weekdays.values.find {|weekday|
          weekday[:kanji] == matched_weekday || weekday[:hiragana] == matched_weekday
        }
        day_text = '次の' + weekday[:kanji] + '曜日'
        data = Nullporter.weather_of_next_weekday(weekday[:key])
      else 
        case
        when body =~ /明日|あした|あす/
          offset_days = 1
          day_text = '明日'
        when body =~ /明[々明]後日|しあさって/
          offset_days = 3
          day_text = '明々後日'
        when body =~ /明後日|あさって/
          offset_days = 2
          day_text = '明後日'
        when body =~ /昨日|きのう/
          return '昨日のは忘れちゃった＞＜'
        else
          offset_days = 0
          day_text = '今日'
        end
        data = Nullporter.weather(offset_days)
      end
      if data
        (day_text + 'は' + data[:telop] + (data[:min_temperature] ? '、最低気温は' + data[:min_temperature].to_s + '度' : '') + (data[:max_temperature] ? '、最高気温は' + data[:max_temperature].to_s + '度' : '') + 'だよー')
      else
        day_text + 'のはわかんない＞＜'
      end
    end
    def tepco
      data = Nullporter.tepco
      '東京電力の現在の電力状況: ' + data['usage'].to_s + '/' + data['capacity'].to_s + '万kW (' + sprintf('%.2f', data['usage'].to_f * 100 / data['capacity'].to_f) + '%) くらい'
    end
    def remove_symbols(s)
      s.gsub(/[\s　☆★\!！\:、\.\[\]\(\)]/, '')
    end
    def for_regexp(regexp, &block)
      lambda {|body|
        if (matches = body.match regexp)
          block.call *((block.arity > 1 || block.arity < 0) ? [body, *matches.captures] : (block.arity == 1 ? [body] : []))
        end
      }
    end
    def fuzzy(regexp, &block)
      lambda {|body| for_regexp(regexp, &block).call remove_symbols(body)}
    end
    def actions
      [
      fuzzy(/([ぬヌﾇ][るルﾙ](ぽ|ポ|([ﾎホ][゜ﾟ])))|nullpo/i) {'ガッ'},
      fuzzy(/([にニﾆ][ゅュｭ][るルﾙ](ぽ|ポ|([ﾎホ][゜ﾟ])))|nyullpo/i) {'にゃっ'},
      fuzzy(/大丈夫か[？?]/) {
        ['大丈夫だ、問題ない。', '一番良いのを頼む。'].pick_random
      },
      fuzzy(/(あず|ごき|ゴキ)にゃん/) {'ペロペロペロペロペロペロペロペロ'},
      fuzzy(/ほむほむ/) {'ぺろぺろぺろぺろ'},
      fuzzy(/[Ss]hine/) {"I'm shining!"},
      fuzzy(/バトルドーム/) {
        ['超！エキサイティンッ！！！', 'ツクダオリジナルから'].pick_random
      },
      fuzzy(/ゆっくり/) {
        'ゆっくりしていってね！！'
      },
      fuzzy(/[おオぉｫｵｫ][はハﾊ][よヨょョﾖｮ]/) {'ｳﾅｷﾞ'},
      fuzzy(/(ダジャレ|だじゃれ|駄洒落|dajare)/i) {Nullporter.dajare},
      fuzzy(/何かを受信/) {Nullporter.hatena_haiku '何かを受信', 15},
      fuzzy(/天気|てんき/) {|body|
        weather remove_symbols body
      },
      fuzzy(/.+(たお|だお|るお|ますお|ですお|ないお|すんなお|ってお)[。.、,!！ｗw☆★\(（…・っッー\-]*\Z/) {75.percent_do {'（ ＾ω＾）おっお'}},
      fuzzy(/おなか/) {75.percent_do {'すいったー'}},
      fuzzy(/onaka/i) {'switter'},
      fuzzy(/(ねむ|眠|ネム|ﾈﾑ)(い|イ|ｲ|ぽ|ポ|ﾎﾟ|げ|ゲ|ｹﾞ|え|エ|ｴ|ぇ|ェ|ｪ|すぎ|スギ|ｽｷﾞ|ー|-|)/) {75.percent_do {'おやすみー'}},
      fuzzy(/murai/i) {'もしかして： おっさん'},
      fuzzy(/いざいざ|イザイザ|ｲｻﾞｲｻﾞ/) {90.percent_do {['ｲﾃﾗ-', 'いてらしゃーい', 'いてらー', 'いてらしあー'].pick_random}},
      fuzzy(/lisp|リスプ/i) {
        50.percent_do {'LISPﾊｧﾊｧ(*´ω｀*)もっと' + ['みーちゃん', 'あづっち', 'さゆさゆ', 'Paul Graham'].pick_random + 'とセツゾクしたいよお！！！！１'}
      },
      fuzzy(/人生宇宙(すべ|全)ての答|answertolifetheuniverseandeverything/i) {
        '42'
      },
      fuzzy(/節電|電力状況/) {tepco}
      ]
    end
    def responses(body)
      actions.map {|action| action.call(body)}.compact
    end
  end
end
class NullpoBot
  def initialize(irc_client)
    @client = irc_client
  end
  def react(message)
    puts '<< ' + message.to_s
    case message.command
    when 'PING'
      @client.pong message.params.join(' ')
    when 'PRIVMSG'
      if message.params[1]
        if message.params[0] =~ /^\#/
          receiver = message.params[0]
        elsif message.prefix && message.prefix.nickname
          receiver = message.prefix.nickname
        else
          receiver = nil
        end
        if receiver
          body = NKF.nkf('-w', message.params[1][0] == ':' ? message.params[1][1, message.params[1].length] : message.params[1])
          NullpoBrain.responses(body).each {|response|
            sleep(response.length / 16 + rand(2))
            @client.privmsg receiver, response.gsub(/[\r\n]/, ' ')
          }
        end
      end
    end
  end
  def received(message)
    begin
      load __FILE__
    rescue Exception
      puts 'Error while reloading: ' + $!.to_s
      $!.backtrace.each {|line| puts line}
    end
    begin
      react message
    rescue
      puts 'Error while reacting: ' + $!.to_s
      $!.backtrace.each {|line| puts line}
    end
  end
  def start
    @client.each_message {|message|
      received message
    }
  end
  def quit
    @client.quit 'でるぽ！'
  end
end
