require 'singleton'

module Jekyll
  module Commands
    # The configuration of the plugin.
    #
    class Configuration
      include Singleton

      DEFAULT_INTERLAYER = '...'
      DEFAULT_FRAGMENTS_DIR = ".fragments"
      DEFAULT_INCLUDE = ["**/*"]


      # A root directory of the source code to be embedded
      attr_reader :code_root

      # A root directory of the documentation files
      attr_reader :documentation_root

      # A list of patterns filtering the code files to be considered.
      #
      # For example, ["**/*.java", "**/*.gradle"]. The default value is "**/*".
      #
      attr_reader :code_includes

      # A directory for the fragmentized code is stored. A temporary directory that should not be
      # tracked VCS.
      attr_reader :fragments_dir

      # A string that's inserted between multiple occurrences of the same fragment.
      #
      # The default value is: "..." (three dots)
      attr_reader :interlayer

      def initialize
        yaml = Jekyll.configuration({})['embed_code']

        @code_root = yaml['code_root']
        @documentation_root = yaml['documentation_root']
        @code_includes = (yaml['code_includes'] or DEFAULT_INCLUDE)
        @fragments_dir = (yaml['fragments_dir'] or DEFAULT_FRAGMENTS_DIR)
        @interlayer = (yaml['interlayer'] or DEFAULT_INTERLAYER)
      end

    end
  end
end
