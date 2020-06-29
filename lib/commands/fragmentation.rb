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

require 'ostruct'
require 'fileutils'
require 'digest/sha1'
require_relative 'configuration'

module Jekyll::Commands

  # Splits the given file into fragments.
  #
  # The fragments are named parts of the file that are surrounded by "fragment brackets":
  # ```
  #    class HelloWorld {
  #        // #docfragment main_method
  #        public static void main(String[] argv) {
  #            // #docfragment printing
  #            System.out.println("Hello World");
  #            // #enddocfragment printing
  #        }
  #        // #enddocfragment main_method
  #    }
  # ```
  #
  # Fragments with the same name may appear multiple times in the same document.
  #
  # Even if no fragments are defined explicitly, the whole file is always a fragment on its own.
  #
  class Fragmentation
    FRAGMENT_START = '#docfragment'.freeze
    FRAGMENT_END = '#enddocfragment'.freeze

    # Creates fragmentation of the given file
    #
    # @param [Object] code_file a full path of a file to fragment
    def initialize(code_file, configuration)
      raise ArgumentError, '`code_file` must be set.' unless code_file
      raise ArgumentError, '`configuration` must be set.' unless configuration

      @configuration = configuration
      @sources_root = File.expand_path(configuration.code_root)
      @code_file = File.expand_path(code_file)
    end

    # Serializes fragments to the output directory.
    #
    # Keeps the original directory structure relative to the @sources_root. That is,
    # `%SRC%/src/main` becomes `%OUT%/src/main`.
    def write_fragments
      content, fragments = fragmentize

      ensure_exists(target_directory)

      fragments.values.each do |fragment|
        file = FragmentFile.from_absolute_file(@code_file, fragment.name, @configuration)
        if fragment.is_default?
          file.write(content)
        else
          first_partition = fragment.partitions[0]
          file.write(partition_content(content, first_partition))
          fragment.partitions[1..nil].each do |part|
            file.append("#{@configuration.interlayer}\n")
            file.append(partition_content(content, part))
          end
        end
      end
    end

    private

    def partition_content(lines, part)
      lines[part.start_position..part.end_position]
    end

    # Splits the file into fragments.
    #
    # @return (content, fragments) a refined content of the file to be cut into fragments, and the Fragments
    def fragmentize
      fragment_builders = {}
      content_to_render = []
      File.open(@code_file).each do |line|
        cursor = content_to_render.length

        fragment_starts = get_fragment_starts(line)
        fragment_ends = get_fragment_ends(line)

        if fragment_starts.any?
          fragment_starts.each do |fragment_name|
            builder = FragmentBuilder.new(@code_file, fragment_name)
            fragment = fragment_builders.fetch(fragment_name, builder)
            fragment.add_start_position(cursor)
            fragment_builders[fragment_name] = fragment
          end
        elsif fragment_ends.any?
          fragment_ends.each do |fragment_name|
            if fragment_builders.key?(fragment_name)
              fragment_builders[fragment_name].add_end_position(cursor - 1)
            else
              raise "Cannot end the fragment `#{fragment_name}` as it wasn't started. " \
                    "File: #{@code_file}"
            end
          end
        else
          content_to_render.push(line)
        end
      end
      fragments = fragment_builders.map { |k, v| [k, v.build] }.to_h
      fragments[Fragment::DEFAULT_FRAGMENT] = Fragment.create_default
      [content_to_render, fragments]
    end

    def target_directory
      fragments_dir = @configuration.fragments_dir
      code_root = File.expand_path(@configuration.code_root)
      relative_file = Pathname.new(@code_file).relative_path_from(code_root).to_s
      sub_tree = File.dirname(relative_file)
      File.join(fragments_dir, sub_tree)
    end

    def ensure_exists(directory)
      unless File.directory?(directory)
        FileUtils.mkdir_p(directory)
      end
    end

    def get_fragment_starts(line)
      lookup(line, FRAGMENT_START)
    end

    def get_fragment_ends(line)
      lookup(line, FRAGMENT_END)
    end

    def lookup(line, prefix)
      if line.include? prefix
        fragments_start = line.index(prefix) + prefix.length + 1 # 1 for trailing space after the prefix
        quoted_fragment_names = line[fragments_start..-1].split(',').map(&:strip)
        unquoted_fragment_names = []
        quoted_fragment_names.each do |name|
          unquoted_fragment_names.push(unquote_and_clean(name))
        end
        unquoted_fragment_names
      else
        []
      end
    end

    def unquote_and_clean(name)
      name.scan(/"(.*)".*/).flatten[0]
    end
  end

  # A single fragment builder.
  #
  class FragmentBuilder

    def initialize(file_name, name = '')
      raise ArgumentError 'Cannot create fragment without a name.' unless name

      @file_name = file_name
      @partitions = []
      @name = name
    end

    # Adds a new partition with the given start position.
    #
    # Don't forget to call `add_end_position` when the end of the fragment is reached.
    #
    # @param [Integer] start_position a starting position of the fragment
    def add_start_position(start_position = 0)
      if @partitions.last and not @partitions.last.end_position
        raise "Unexpected fragment start at #{start_position}. " \
              "Fragment `#{name}` already started on line #{@partitions.last.start_position}."
      end
      partition = OpenStruct.new('start_position' => start_position, 'end_position' => nil)
      @partitions.push(partition)
      self
    end

    # Completes previously created fragment partition with its end position.
    #
    # Should be called after `add_start_position`.
    #
    # @param [Integer] end_position an end position position of the fragment
    def add_end_position(end_position = 0)
      last = @partitions.last
      if not last or last.end_position
        raise StandardError,
              "Unexpected #enddocfragment statement at #{@file_name}:#{end_position}."
      end
      last.end_position = end_position
      self
    end

    # Builds a fragment
    #
    def build
      Fragment.new(@name, @partitions)
    end
  end

  # A single fragment in a file
  #
  class Fragment
    DEFAULT_FRAGMENT = '_default'

    attr_reader :name
    attr_reader :partitions

    def initialize(name = '', partitions = [])
      unless name and partitions
        raise ArgumentError, 'Cannot create a fragment.'
      end
      @partitions = partitions
      @name = name
    end

    def self.create_default
      Fragment.new(DEFAULT_FRAGMENT, [])
    end

    def is_default?
      @name == DEFAULT_FRAGMENT
    end
  end

  # A file storing a single fragment from the file.
  #
  # The physical file on the disk may not exists.
  #
  class FragmentFile

    # @param [string] code_file a relative path to a code file
    # @param [string] fragment_name a name of the fragment in the code file
    # @param [Configuration] configuration the embedding configuration
    def initialize(code_file, fragment_name, configuration)
      @code_file = code_file
      @fragment_name = fragment_name
      @configuration = configuration
    end

    # Composes a FragmentFile for the given fragment in the given code file.
    #
    # @param [string] code_file an absolute path to a code file
    # @param [string] fragment the fragment
    def self.from_absolute_file(code_file, fragment_name, configuration)
      code_file = Pathname.new(code_file)
      code_root = File.expand_path(configuration.code_root)
      relative_path = code_file.relative_path_from code_root
      return FragmentFile.new(relative_path.to_s, fragment_name, configuration)
    end

    # Obtains the absolute path to this fragment file
    def absolute_path
      file_extension = File.extname(@code_file)
      fragments_dir = File.expand_path(@configuration.fragments_dir)

      if @fragment_name == Fragment::DEFAULT_FRAGMENT
        File.join(fragments_dir, @code_file)
      else
        base_name = File.basename(@code_file, '.*')
        without_extension = File.join(File.dirname(@code_file), base_name)
        filename = "#{without_extension}-#{fragment_hash}"
        File.join(fragments_dir, filename + file_extension)
      end
    end

    # Reads content of the file.
    #
    # @return contents of the file or nil if it doesn't exist
    def content
      path = absolute_path
      raise "Fragment file `#{path}` not found." unless File.exist?(path)

      File.readlines(path)
    end

    # Writes contents to the file.
    #
    # Overwrites the file if it exists.
    def write(content)
      write_lines content, 'w+'
    end

    def append(content)
      write_lines content, 'a+'
    end

    def exists?
      File.exist? absolute_path
    end

    private

    def write_lines(content, open_mode)
      File.open(absolute_path, open_mode) do |f|
        indentation = find_minimal_indentation(content)
        content.each do |line|
          f.puts(line[indentation..-1])
        end
      end
    end

    def fragment_hash
      # Allows to use any characters in a fragment name
      (Digest::SHA1.hexdigest @fragment_name)[0..7]
    end

    def find_minimal_indentation(lines)
      min_indentation = Float::INFINITY
      lines.each do |line|
        unless line.strip.empty?
          spaces = line[/\A */].size
          if spaces < min_indentation
            min_indentation = spaces
          end
        end
      end
      min_indentation
    end
  end
end
