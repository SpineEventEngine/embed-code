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

class EmbeddingInstructionTest < Test::Unit::TestCase

  def test_parse_from_xml
    xml = build_instruction 'org/example/Hello.java', 'Hello class'
    configuration = create_config
    instruction = Jekyll::Commands::EmbeddingInstruction.from_xml(xml, configuration)
    assert_not_nil(instruction)
  end

  def test_read_fragment_dir
    xml = build_instruction 'org/example/Hello.java'
    configuration = create_config
    instruction = Jekyll::Commands::EmbeddingInstruction.from_xml(xml, configuration)
    lines = instruction.content
    assert_not_nil(lines)
    assert_equal(28, lines.size)
    assert_equal("public class Hello {\n", lines[22])
  end

  def create_config(prepared_fragments = true)
    fragments_dir = prepared_fragments ? './test/prepared-fragments' : './test/fragments'
    yaml_like_hash = {
      'embed_code' => {
        'code_root' => './test/code',
        'fragments_dir' => fragments_dir,
        'documentation_root' => './'
      }
    }
    Jekyll::Commands::Configuration.new(yaml_like_hash)
  end

  def build_instruction(file_name, fragment = nil)
    fragment_attr = fragment ? "fragment=\"#{fragment}\"" : ''
    "<?embed-code file=\"#{file_name}\" #{fragment_attr}?>"
  end

end
