require "active_support/core_ext/integer"
require "time"

module AwsLogs
  class Since
    DEFAULT = 10.minutes.to_i

    def initialize(str)
      @str = str
    end

    def to_i
      if iso8601_format?
        iso8601_seconds
      elsif friendly_format?
        friendly_seconds
      else
        puts warning
        return DEFAULT
      end
    end

    ISO8601_REGEXP = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
    def iso8601_format?
      !!@str.match(ISO8601_REGEXP)
    end

    def iso8601_seconds
      # https://stackoverflow.com/questions/3775544/how-do-you-convert-an-iso-8601-date-to-a-unix-timestamp-in-ruby
      Time.iso8601(@str.sub(/ /,'T')).to_i
    end

    FRIENDLY_REGEXP = /(\d+)(\w+)/
    def friendly_format?
      !!@str.match(FRIENDLY_REGEXP)
    end

    def friendly_seconds
      number, unit = find_match(FRIENDLY_REGEXP)
      unless number && unit
        puts warning
        return DEFAULT
      end

      meth = shorthand(unit)
      if number.respond_to?(meth)
        number.send(meth).to_i
      else
        puts warning
        return DEFAULT
      end
    end

    def find_match(regexp)
      md = @str.match(regexp)
      if md
        number, unit = md[1].to_i, md[2]
      end
      [number, unit]
    end

    def warning
      "WARN: since is not in a supported format. Falling back to 10m".color(:yellow)
    end

    # s - seconds
    # m - minutes
    # h - hours
    # d - days
    # w - weeks
    def shorthand(k)
      map = {
        s: :seconds,
        m: :minutes,
        h: :hours,
        d: :days,
        w: :weeks,
      }
      map[k.to_sym] || k
    end
  end
end