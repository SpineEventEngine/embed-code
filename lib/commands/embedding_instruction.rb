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

require 'nokogiri'

require_relative 'fragmentation'
require_relative 'indent'

module EmbedCode

  # Specifies the code fragment to embed into a Markdown file, and the embedding parameters.
  #
  # Takes form of an XML processing instruction <embed-code file="..." fragment="..."/>.
  #
  # The following parameters are currently supported:
  # * 'file' a mandatory relative path to the file with the code
  # * 'fragment' an optional name of the particular fragment in the code. If no fragment is specified,
  # the whole file is embedded.
  #
  class EmbeddingInstruction
    STATEMENT = '<embed-code'.freeze
    TAG_NAME = 'embed-code'.freeze

    def initialize(values, configuration)
      @code_file = values['file']
      @fragment = values['fragment']
      start_value = values['start']
      @start = start_value ? Pattern.new(start_value) : nil
      end_value = values['end']
      @end = end_value ? Pattern.new(end_value) : nil
      if !@fragment.nil? && (!@start.nil? || !@end.nil?)
        raise ArgumentError,
              '<embed-code> must NOT specify both a fragment name and start/end patterns.'
      end
      @configuration = configuration
    end

    # Reads the instruction from the '<embed-code>' XML tag.
    #
    # @param [Object] line line with the XML
    # @param [Configuration] configuration tool configuration
    def self.from_xml(line, configuration)
      begin
        document = Nokogiri::XML(line, nil, nil, Nokogiri::XML::ParseOptions::STRICT)
        instruction = document.at_xpath("//#{TAG_NAME}")
      rescue StandardError
        return nil
      end
      if instruction.nil?
        return nil
      end
      fields = instruction.attributes.map { |name, value| [name, value.to_s] }.to_h
      EmbeddingInstruction.new(fields, configuration)
    end

    # Reads the specified fragment from the code.
    #
    def content
      fragment_name = @fragment || Fragment::DEFAULT_FRAGMENT
      file = FragmentFile.new(@code_file, fragment_name, @configuration)
      if @start || @end
        matching_lines(file.content)
      else
        file.content
      end
    end

    def to_s
      "EmbeddingInstruction[file=`#{@code_file}`, fragment=`#{@fragment}`, " \
                           "start=`#{@start}`, end=`#{@end}`]"
    end

    private

    def matching_lines(lines)
      start_position = @start ? match_glob(@start, lines, 0) : 0
      end_position = @end ? match_glob(@end, lines, start_position) : nil

      required_lines = lines[start_position..end_position]
      indentation = max_common_indentation(required_lines)
      cut_indent(required_lines, indentation)
    end

    def match_glob(pattern, lines, start_from)
      line_count = lines.length
      result_line = start_from
      until result_line >= line_count
        line = lines[result_line]
        return result_line if pattern.match?(line)

        result_line += 1
      end
      raise "There is no line matching `#{pattern}`."
    end
  end

  # A glob-like pattern to match a line of a source file.
  #
  class Pattern

    def initialize(glob)
      @source_glob = glob
      pattern = glob
      start_of_line = glob.start_with?('^')
      if !start_of_line && !glob.start_with?('*')
        pattern = '*' + pattern
      end
      if start_of_line
        pattern = pattern[1..nil]
      end
      end_of_line = glob.end_with?('$')
      if !end_of_line && !glob.end_with?('*')
        pattern += '*'
      end
      if end_of_line
        pattern = pattern[0..pattern.length - 2]
      end

      @pattern = pattern
    end

    def match?(line)
      File.fnmatch?(@pattern, line.chomp)
    end

    def to_s
      "Pattern #{@source_glob}"
    end
  end

  private_constant :Pattern

end
