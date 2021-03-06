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
require 'fileutils'
require_relative '../../lib/commands/embedding_instruction'
require_relative '../../lib/commands/configuration'
require_relative './given/test_env'

class FragmentationTest < Test::Unit::TestCase

  def teardown
    delete_dir config.fragments_dir
  end

  def test_fragmentize_file
    configuration = config
    file_name = 'Hello.java'
    path = "#{configuration.code_root}/org/example/#{file_name}"
    fragmentation = Jekyll::Commands::Fragmentation.new(path, configuration)
    fragmentation.write_fragments

    fragment_children = Dir.children(configuration.fragments_dir)
    assert_equal 1, fragment_children.size
    assert_equal 'org', fragment_children[0]

    fragment_files = Dir.children("#{configuration.fragments_dir}/org/example")

    assert_equal 4, fragment_files.size
    # Check "default" fragment exists.
    assert fragment_files.include? file_name

    fragment_files.each do |file|
      assert_match(/Hello-\w+\.java/, file) unless file == file_name
    end
  end

  def test_requires_code_file
    assert_raise ArgumentError do
      Jekyll::Commands::Fragmentation.new(nil, config)
    end
  end

  def test_requires_config
    assert_raise ArgumentError do
      Jekyll::Commands::Fragmentation.new('foo/bar', nil)
    end
  end

  def test_fail_not_open_fragment
    configuration = config
    path = "#{configuration.code_root}/org/example/Unopen.java"
    fragmentation = Jekyll::Commands::Fragmentation.new(path, configuration)
    assert_raise do
      fragmentation.write_fragments
    end
  end

  def test_fragment_without_end
    configuration = config
    file_name = 'Unclosed.java'
    path = "#{configuration.code_root}/org/example/#{file_name}"
    fragmentation = Jekyll::Commands::Fragmentation.new(path, configuration)
    fragmentation.write_fragments

    fragment_dir = "#{configuration.fragments_dir}/org/example"
    fragment_files = Dir.children(fragment_dir)
    assert_equal 2, fragment_files.size

    fragment_files.delete file_name

    fragment_content = File.read "#{fragment_dir}/#{fragment_files[0]}"
    assert_match(/^[.\n\s]+}\n}$/, fragment_content)
  end

  def test_fragmentize_empty_file
    configuration = config
    file_name = 'Empty.java'
    path = "#{configuration.code_root}/org/example/#{file_name}"
    fragmentation = Jekyll::Commands::Fragmentation.new(path, configuration)
    fragmentation.write_fragments

    fragment_dir = "#{configuration.fragments_dir}/org/example"
    fragment_files = Dir.children(fragment_dir)
    assert_equal 1, fragment_files.size

    fragment_content = File.read "#{fragment_dir}/#{fragment_files[0]}"
    assert_match(/^$/, fragment_content)
  end

  def test_ignore_binary
    configuration = config(false, ['**/*.jar'])
    Jekyll::Commands::Fragmentation.write_fragment_files(configuration)
    assert_false File.exist?(configuration.fragments_dir)
  end

  def test_many_partitions
    configuration = config
    file_name = 'Complex.java'
    path = "#{configuration.code_root}/org/example/#{file_name}"
    fragmentation = Jekyll::Commands::Fragmentation.new(path, configuration)
    fragmentation.write_fragments

    fragment_dir = "#{configuration.fragments_dir}/org/example"
    fragment_files = Dir.children(fragment_dir)
    assert_equal 2, fragment_files.size

    fragment_files.delete file_name

    fragment_lines = File.readlines("#{fragment_dir}/#{fragment_files[0]}", chomp: true)
    assert_equal('public class Main {', fragment_lines[0])
    assert_equal(configuration.separator, fragment_lines[1])
    assert_match(/\s{4}public.*/, fragment_lines[2])
    assert_equal(configuration.separator, fragment_lines[3])
    assert_match(/\s{8}System.*/, fragment_lines[4])
    assert_equal('', fragment_lines[5])
    assert_equal('    }', fragment_lines[6])
    assert_equal(configuration.separator, fragment_lines[7])
    assert_equal('}', fragment_lines[8])
  end
end
