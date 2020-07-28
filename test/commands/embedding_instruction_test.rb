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

  def test_fragment_and_start
    xml = build_instruction 'org/example/Hello.java', 'fr1', 'public void hello()'
    assert_raise ArgumentError do
      Jekyll::Commands::EmbeddingInstruction.from_xml(xml, config_with_prepared_fragments)
    end
  end

  def test_fragment_and_end
    xml = build_instruction 'org/example/Hello.java', 'fr2', nil, '}'
    assert_raise ArgumentError do
      Jekyll::Commands::EmbeddingInstruction.from_xml(xml, config_with_prepared_fragments)
    end
  end

  def test_extract_by_glob
    xml = build_instruction 'org/example/Hello.java', nil, 'public class*', '*System.out*'
    configuration = config_with_prepared_fragments
    instruction = Jekyll::Commands::EmbeddingInstruction.from_xml(xml, configuration)
    lines = instruction.content
    assert_not_nil(lines)
    assert_equal(4, lines.size)
    assert_equal("public class Hello {\n", lines.first)
    assert_equal("        System.out.println(\"Hello world\");\n", lines.last)
  end

  def test_min_indentation
    xml = build_instruction 'org/example/Hello.java', nil, '*public static void main*', '*}*'
    configuration = config_with_prepared_fragments
    instruction = Jekyll::Commands::EmbeddingInstruction.from_xml(xml, configuration)
    lines = instruction.content
    assert_not_nil(lines)
    assert_equal(3, lines.size)
    assert_not_equal(' ', lines.first[0])
    assert_match(/^public.+/, lines.first)
    assert_match(/\s{4}.+/, lines[1])
    assert_equal("}\n", lines.last)
  end

  def test_start_without_end
    xml = build_instruction 'org/example/Hello.java', nil, '*class*'
    configuration = config_with_prepared_fragments
    instruction = Jekyll::Commands::EmbeddingInstruction.from_xml(xml, configuration)
    lines = instruction.content
    assert_not_nil(lines)
    assert_equal(6, lines.size)
    assert_equal("}\n", lines.last)
  end

  def test_end_without_start
    xml = build_instruction 'org/example/Hello.java', nil, nil, 'package*'
    configuration = config_with_prepared_fragments
    instruction = Jekyll::Commands::EmbeddingInstruction.from_xml(xml, configuration)
    lines = instruction.content
    assert_not_nil(lines)
    assert_equal(21, lines.size)
    assert_equal("/*\n", lines.first)
    assert_equal("package org.example;\n", lines.last)
  end

  def test_one_line
    xml = build_instruction 'org/example/Hello.java', nil, '*main*', '*main*'
    configuration = config_with_prepared_fragments
    instruction = Jekyll::Commands::EmbeddingInstruction.from_xml(xml, configuration)
    lines = instruction.content
    assert_not_nil(lines)
    assert_equal(1, lines.size)
    assert_equal("public static void main(String[] args) {\n", lines.first)
  end

  def test_no_match_start
    xml = build_instruction 'org/example/Hello.java', nil, 'foo bar', '*main*'
    configuration = config_with_prepared_fragments
    instruction = Jekyll::Commands::EmbeddingInstruction.from_xml(xml, configuration)
    assert_raise do
      instruction.content
    end
  end

  def test_no_match_end
    xml = build_instruction 'org/example/Hello.java', nil, '*main*', 'foo bar'
    configuration = config_with_prepared_fragments
    instruction = Jekyll::Commands::EmbeddingInstruction.from_xml(xml, configuration)
    assert_raise do
      instruction.content
    end
  end
end
