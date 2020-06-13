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
require_relative('configuration')

module Jekyll
  module Commands

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
      FRAGMENT_START = "#docfragment"
      FRAGMENT_END = "#enddocfragment"

      # Creates fragmentation of the given file
      #
      # @param [Object] code_file a full path of a file to fragment
      def initialize(code_file = "")
        unless code_file
          raise ArgumentError.new "Failed to create Fragmentation"
        end
        @sources_root = File.expand_path(Configuration.instance.code_root)
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
          if fragment.is_default?
            file = FragmentFile.from_absolute_file(@code_file, fragment.name, nil)
            file.write(content)
          else
            fragment.occurrences.each_with_index do |occurrence, index|
              file = FragmentFile.from_absolute_file(@code_file, fragment.name, index)
              fragment_content = content[occurrence.start_position..occurrence.end_position]
              file.write(fragment_content)
            end
          end
        end
      end

      private

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
            fragment_starts.each { |fragment_name|
              fragment = fragment_builders.fetch(fragment_name, FragmentBuilder.new(fragment_name))
              fragment.add_start_position(cursor)
              fragment_builders[fragment_name] = fragment
            }
          elsif fragment_ends.any?
            fragment_ends.each { |fragment_name|
              if fragment_builders.key?(fragment_name)
                fragment_builders[fragment_name].add_end_position(cursor - 1)
              else
                raise StandardError.new "Can't end a fragment that wasn't started: #{fragment_name}"
              end
            }
          else
            content_to_render.push(line)
          end
        end
        fragments = fragment_builders.map { |k, v| [k, v.build] }.to_h
        fragments[Fragment::DEFAULT_FRAGMENT] = Fragment.create_default
        [content_to_render, fragments]
      end

      def target_directory
        fragments_dir = Configuration.instance.fragments_dir
        code_root = File.expand_path(Configuration.instance.code_root)
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

      def initialize(name = "")
        unless name
          raise ArgumentError.new "Can't create fragment without a name"
        end
        @occurrences = []
        @name = name
      end

      # Adds a new occurrence with the given start position.
      #
      # Don't forget to call `add_end_position` when the end of the fragment is reached.
      #
      # @param [Integer] start_position a starting position of the fragment
      def add_start_position(start_position = 0)
        if @occurrences.last and not @occurrences.last.end_position
          raise ArgumentError.new "Overlapping fragment detected: " + @name
        end
        occurrence = OpenStruct.new("start_position" => start_position, "end_position" => nil)
        @occurrences.push(occurrence)
        self
      end

      # Completes previously created occurrence with its end position.
      #
      # Should be called after `add_start_position`.
      #
      # @param [Integer] end_position an end position position of the fragment
      def add_end_position(end_position = 0)
        last = @occurrences.last
        if not last or (last and last.end_position)
          raise ArgumentError.new "Unexpected #enddocfragment statement"
        end
        last.end_position = end_position
        self
      end

      # Builds a fragment
      #
      def build
        Fragment.new(@name, @occurrences)
      end
    end

    # A single fragment in a file
    #
    class Fragment
      DEFAULT_FRAGMENT = "_default"

      def initialize(name = "", occurrences = [])
        unless name and occurrences
          raise ArgumentError.new "Can't create a fragment"
        end
        @occurrences = occurrences
        @name = name
      end

      def self.create_default
        Fragment.new(DEFAULT_FRAGMENT, [])
      end

      def is_default?
        @name == DEFAULT_FRAGMENT
      end

      attr_reader :name
      attr_reader :occurrences
    end

    # A file storing a single fragment from the file.
    #
    # The physical file on the disk may not exists.
    #
    class FragmentFile

      # @param [string] code_file a relative path to a code file
      # @param [string] fragment_name a name of the fragment in the code file
      # @param [string] fragment_index an index of the fragment occurrence in the file
      def initialize(code_file, fragment_name, fragment_index = nil)
        @code_file = code_file
        @fragment_name = fragment_name
        @fragment_index = fragment_index
      end

      # Composes a FragmentFile for the given fragment in the given code file.
      #
      # @param [string] code_file an absolute path to a code file
      # @param [string] fragment the fragment
      # @param [integer] fragment_index an index of the fragment occurrence in the file
      def self.from_absolute_file(code_file, fragment_name, fragment_index)
        code_file = Pathname.new code_file
        code_root = File.expand_path Configuration.instance.code_root
        relative_path = code_file.relative_path_from code_root
        return FragmentFile.new(relative_path.to_s, fragment_name, fragment_index)
      end

      # Obtains the absolute path to this fragment file
      def absolute_path
        file_extension = File.extname(@code_file)
        fragments_dir = File.expand_path(Configuration.instance.fragments_dir)

        if @fragment_name == Fragment::DEFAULT_FRAGMENT
          File.join(fragments_dir, @code_file)
        else
          without_extension = File.join(File.dirname(@code_file), File.basename(@code_file))
          filename = "#{without_extension}-#{fragment_hash}-#{@fragment_index}"
          File.join(fragments_dir, filename + file_extension)
        end
      end

      # Reads content of the file.
      #
      # @return contents of the file or nil if it doesn't exist
      def content
        path = absolute_path
        if File.exist?(path)
          File.readlines(path)
        else
          nil
        end
      end

      # Writes contents to the file.
      #
      # Overwrites the file if it exists.
      def write(content)
        File.open(absolute_path, "w+") do |f|
          indentation = find_minimal_indentation(content)
          content.each { |line|
            f.puts(line[indentation..-1])
          }
        end
      end

      private

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
end
