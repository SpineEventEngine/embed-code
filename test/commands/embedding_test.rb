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

require 'test/unit'
require_relative '../../lib/commands/configuration'
require_relative '../../lib/commands/embedding'
require_relative '../../lib/commands/errors'
require_relative './given/test_env'

class EmbeddingProcessorTest < Test::Unit::TestCase

  def setup
    @config = config_with_prepared_fragments
    prepare_docs './test/resources/docs'
  end

  def teardown
    delete_dir @config.documentation_root
  end

  def test_not_up_to_date
    processor = EmbedCode::EmbeddingProcessor.new(
      "#{@config.documentation_root}/whole-file-fragment.md", @config
    )
    assert !processor.up_to_date?
  end

  def test_up_to_date
    processor = EmbedCode::EmbeddingProcessor.new(
      "#{@config.documentation_root}/whole-file-fragment.md", @config
    )
    processor.embed
    assert processor.up_to_date?
  end

  def test_nothing_to_update
    processor = EmbedCode::EmbeddingProcessor.new(
      "#{@config.documentation_root}/no-embedding-doc.md", @config
    )
    assert processor.up_to_date?
  end
end
