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
require_relative '../../lib/commands/check_command'
require_relative '../../lib/commands/configuration'
require_relative '../../lib/commands/errors'
require_relative './given/test_env'

class CheckCodeSamplesTest < Test::Unit::TestCase

  def setup
    prepare_docs './test/resources/docs'
  end

  def teardown
    delete_dir @config.documentation_root
    delete_dir @config.fragments_dir
  end

  def test_not_up_to_date
    @config = config(false, ['**/Hello.java'], ['**/doc.md'])
    assert_raise Jekyll::Commands::UnexpectedDiffError do
      Jekyll::Commands::CheckCodeSamples.process @config
    end
  end

  def test_up_to_date
    @config = config(false, ['**/Hello.java'], ['**/already-embedded.md'])
    assert_nothing_raised do
      Jekyll::Commands::CheckCodeSamples.process @config
    end
  end

  def test_nothing_to_update
    @config = config(false, ['**/Hello.java'], ['**/already-embedded.md'])
    assert_nothing_raised do
      Jekyll::Commands::CheckCodeSamples.process @config
    end
  end
end
