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
require_relative '../../lib/commands/indent'

class IndentationTest < Test::Unit::TestCase

  def test_no_spaces
    indent = max_common_indentation ['', 'foo', 'bar', '', 'baz', '']
    assert_equal 0, indent
  end

  def test_no_lines
    indent = max_common_indentation []
    assert_equal 0, indent
  end

  def test_only_empty_lines
    indent = max_common_indentation ['', '    ', '']
    assert_equal 0, indent
  end

  def test_2_spaces
    indent = max_common_indentation ['', '  foo', '    bar', '', '', '  baz']
    assert_equal 2, indent
  end
end
