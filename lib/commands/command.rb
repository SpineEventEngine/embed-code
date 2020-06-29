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

require('jekyll')
require_relative('fragmentation')
require_relative('embedding')
require_relative('configuration')

# Usage example:
#   bundle exec jekyll embedCodeSamples
#

module Jekyll::Commands

  # Command which updates code embeddings in the documentation files.
  class EmbedCodeSamples < Jekyll::Command

    def self.init_with_program(prog)
      prog.command(:embedCodeSamples) do |c|
        c.syntax 'embedCode'
        c.description 'Embeds sample code to Markdown files'
        c.action { |_, __| process(Configuration.from_file) }
      end
    end

    def self.process(configuration)
      cmd = EmbedCodeSamples.new
      cmd.write_code_fragments configuration
      cmd.embed_code_fragments configuration
    end

    def write_code_fragments(configuration)
      includes = configuration.code_includes
      code_root = configuration.code_root
      includes.each do |rule|
        pattern = "#{code_root}/#{rule}"
        Dir.glob(pattern) do |code_file|
          if File.file? code_file
            puts code_file
            Fragmentation.new(code_file, configuration).write_fragments
          end
        end
      end
    end

    def embed_code_fragments(configuration)
      documentation_root = configuration.documentation_root
      doc_patterns = configuration.doc_includes
      doc_patterns.each do |pattern|
        Dir.glob("#{documentation_root}/#{pattern}") do |documentation_file|
          EmbeddingProcessor.new(documentation_file, configuration).embed
        end
      end
    end
  end
end
