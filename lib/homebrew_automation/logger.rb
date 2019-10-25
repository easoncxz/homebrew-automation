
require 'time'

module HomebrewAutomation

  # Help you see which parts of STDOUT came from HomebrewAutomation
  class Logger

    def info!(msg)
      puts(bold(green("homebrew_automation.rb [info] (#{DateTime.now}): ")) + msg)
    end

    def error!(msg)
      puts(red("homebrew_automation.rb [error] (#{DateTime.now}): ") + msg)
    end

    private

    # https://stackoverflow.com/questions/1489183/colorized-ruby-output
    def coloured(colour, msg)
      "\e[#{colour}m#{msg}\e[0m"
    end

    def green(x)
      coloured(32, x)
    end

    def red(x)
      coloured(31, x)
    end

    def bold(x)
      "\e[1m#{x}\e[22m"
    end

  end

end
