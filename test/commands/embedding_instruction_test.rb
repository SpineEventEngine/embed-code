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
require_relative '../../lib/commands/embedding_instruction'
require_relative '../../lib/commands/configuration'
require_relative './given/test_env'

class EmbeddingInstructionTest < Test::Unit::TestCase

  def test_parse_from_xml
    xml = build_instruction 'org/example/Hello.java', 'Hello class'
    configuration = config_with_prepared_fragments
    instruction = Jekyll::Commands::EmbeddingInstruction.from_xml(xml, configuration)
    assert_not_nil(instruction)
  end

  def test_read_fragment_dir
    xml = build_instruction 'org/example/Hello.java'
    configuration = config_with_prepared_fragments
    instruction = Jekyll::Commands::EmbeddingInstruction.from_xml(xml, configuration)
    lines = instruction.content
    assert_not_nil(lines)
    assert_equal(28, lines.size)
    assert_equal("public class Hello {\n", lines[22])
  end
end
