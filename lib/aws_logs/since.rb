require "active_support/core_ext/integer"

module AwsLogs
  class Since
    def initialize(str)
      @str = str
      @fallback = 10.minutes
    end

    def to_i
      number, unit = match(/(\d+)(\w+)/)
      unless number && unit
        puts warning
        return @fallback
      end

      meth = shorthand(unit)
      if number.respond_to?(meth)
        number.send(meth)
      else
        puts warning
        return @fallback
      end
    end

    def match(regexp)
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