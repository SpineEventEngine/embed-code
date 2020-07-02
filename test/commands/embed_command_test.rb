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
require_relative '../../lib/commands/embed_command'
require_relative '../../lib/commands/configuration'
require_relative './given/test_env'

class EmbedCodeSamplesTest < Test::Unit::TestCase

  def setup
    @config = config(false, ['**/Hello.java'])
    prepare_docs './test/resources/docs'
  end

  def teardown
    delete_dir @config.fragments_dir
    delete_dir @config.documentation_root
  end

  def test_process_files
    main_method_regex = /^public static void main.*/

    doc_file = "#{@config.documentation_root}/doc.md"
    initial_content = File.read doc_file
    assert_no_match(main_method_regex, initial_content)

    Jekyll::Commands::EmbedCodeSamples.process(@config)

    updated_content = File.read doc_file
    assert_match(main_method_regex, updated_content)
  end
end
