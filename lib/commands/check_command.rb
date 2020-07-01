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
require_relative('configuration')
require_relative('embedding')
require_relative('fragmentation')


# Usage example:
#   bundle exec jekyll checkCodeSamples
#

module Jekyll::Commands

  # Command which updates code embeddings in the documentation files.
  class CheckCodeSamples < Jekyll::Command

    def self.init_with_program(prog)
      prog.command('checkCodeSamples') do |c|
        c.description 'Checks that the doc files are up to date with the sample code.'
        c.action { |_, __| process(Configuration.from_file) }
      end
    end

    def self.process(configuration)
      Fragmentation.write_fragment_files configuration
      EmbeddingProcessor.check_up_to_date configuration
    end
  end
end
