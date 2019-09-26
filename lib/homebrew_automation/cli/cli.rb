
require 'thor'

require_relative 'formula_commands.rb'
require_relative 'workflow_commands.rb'

module HomebrewAutomation
  module CLI

    class MyCliApp < Thor

      desc 'version', 'version of homebrew_automation'
      def version
        puts HomebrewAutomation::VERSION
      end

      desc 'formula (...)', 'Modify Formula DSL source (read stdin, write stdout)'
      subcommand "formula", FormulaCommands

      desc 'bottle (...)', 'Workflows for dealing with binary artifacts'
      subcommand "bottle", WorkflowCommands

    end

  end
end

