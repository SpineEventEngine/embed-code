require_relative('fragmentation')
require_relative('embedding')
require_relative('configuration')

# Usage example:
#   bundle exec jekyll embedCodeSamples
#

module Jekyll
  module Commands
    class EmbedCodeSamples < Command

      def self.init_with_program(prog)
        prog.command(:embedCodeSamples) do |c|
          c.syntax "embedCode"
          c.description "Embeds sample code to Markdown files"

          c.action { |args, options| process(args, options) }
        end
      end

      def self.process(args = [], options = {})
        configuration = Configuration.instance

        includes = configuration.code_includes
        code_root = configuration.code_root
        includes.each do |rule|
          pattern = "#{code_root}/#{rule}"
          Dir.glob(pattern) { |code_file|
            Fragmentation.new(code_file).write_fragments
          }
        end

        documentation_root = configuration.documentation_root
        Dir.glob("#{documentation_root}/**/*.md") { |documentation_file|
          EmbeddingProcessor.new(documentation_file).embed
        }
      end
    end
  end
end
