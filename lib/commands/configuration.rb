# Copyright 2020, TeamDev. All rights reserved.
#
# Redistribution and use in source and/or binary forms, with or without
# modification, must retain the above copyright notice and the following
# disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'jekyll'
require 'singleton'

module Jekyll::Commands
  # The configuration of the plugin.
  #
  class Configuration

    DEFAULT_INTERLAYER = '...'.freeze
    DEFAULT_FRAGMENTS_DIR = '.fragments'.freeze
    DEFAULT_INCLUDE = ['**/*'].freeze
    DEFAULT_DOC_INCLUDES = ['**/*.md', '**/*.html'].freeze

    # A root directory of the source code to be embedded
    attr_reader :code_root

    # A root directory of the documentation files
    attr_reader :documentation_root

    # A list of patterns filtering the code files to be considered.
    #
    # Directories are never matched by these patterns.
    #
    # For example, ["**/*.java", "**/*.gradle"]. The default value is "**/*".
    #
    attr_reader :code_includes

    # A list of patterns filtering files in which we should look for embedding instructions.
    #
    # The patterns are resolved relatively to the `documentation_root`.
    #
    # Directories are never matched by these patterns.
    #
    # For example, ["docs/**/*.md", "guides/*.html"]. The default value is
    # ["**/*.md", "**/*.html"].
    #
    attr_reader :doc_includes

    # A directory for the fragmentized code is stored. A temporary directory that should not be
    # tracked VCS.
    attr_reader :fragments_dir

    # A string that's inserted between multiple occurrences of the same fragment.
    #
    # The default value is: "..." (three dots)
    attr_reader :interlayer

    def initialize(yaml_config)
      yaml = yaml_config['embed_code']
      if yaml.nil?
        raise 'Missing Jekyll configuration. A minimal `embed_code` section should be present in' \
              '`_config.yml`.'
      end
      @code_root = yaml['code_root']
      @documentation_root = yaml['documentation_root']
      @code_includes = (yaml['code_includes'] or DEFAULT_INCLUDE)
      @doc_includes = (yaml['doc_includes'] or DEFAULT_DOC_INCLUDES)
      @fragments_dir = (yaml['fragments_dir'] or DEFAULT_FRAGMENTS_DIR)
      @interlayer = (yaml['interlayer'] or DEFAULT_INTERLAYER)
    end

    def self.from_file
      FileConfiguration.instance.config
    end
  end

  class FileConfiguration
    include Singleton

    attr_reader :config

    def initialize
      yaml = Jekyll.configuration({})['embed_code']
      @configuration = Configuration.new yaml
    end
  end
end
