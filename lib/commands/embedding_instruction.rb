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
require 'jekyll'

require_relative 'fragmentation'
require_relative 'indent'

module Jekyll::Commands

  # Specifies the code fragment to embed into a Markdown file, and the embedding parameters.
  #
  # Takes form of an XML processing instruction <?embed-code file="..." fragment="..."?>.
  #
  # The following parameters are currently supported:
  # * 'file' a mandatory relative path to the file with the code
  # * 'fragment' an optional name of the particular fragment in the code. If no fragment is specified,
  # the whole file is embedded.
  #
  class EmbeddingInstruction
    STATEMENT = '<?embed-code'.freeze
    TAG_NAME = 'embed-code'.freeze

    def initialize(values, configuration)
      @code_file = values['file']
      @fragment = values['fragment']
      @start = values['start']
      @end = values['end']

      if !@fragment.nil? && (!@start.nil? || !@end.nil?)
        raise ArgumentError,
              '<?embed-code?> should not specify both a fragment name and start/end patterns.'
      end

      @configuration = configuration
    end

    # Reads the instruction from the '<?embed-code?>' XML tag.
    #
    # @param [Object] line line with the XML
    # @param [Configuration] configuration tool configuration
    def self.from_xml(line, configuration)
      begin
        document = Nokogiri::XML(line)
        instruction = document.at_xpath("//processing-instruction('#{TAG_NAME}')")
      rescue StandardError => e
        puts e
        return nil
      end
      if instruction.nil?
        return nil
      end
      tag = instruction.to_element
      fields = tag.attributes.map { |name, value| [name, value.to_s] }.to_h
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

    private

    def matching_lines(lines)
      start_position = @start ? match_glob(@start, lines, 0) : 0
      end_position = @end ? match_glob(@end, lines, start_position) : nil

      required_lines = lines[start_position..end_position]
      indentation = max_common_indentation(required_lines)
      required_lines.map { |line| line[indentation..-1] }
    end

    def match_glob(pattern, lines, start_from)
      line_count = lines.length
      result_line = start_from
      until result_line >= line_count
        line = lines[result_line]
        return result_line if File.fnmatch?(pattern, line)

        result_line += 1
      end
      raise "There is no line matching `#{pattern}`."
    end
  end
end

module Nokogiri::XML
  # Extends Nokogiri's class with 'to_element' method.
  #
  class ProcessingInstruction

    # Creates new element based on the content of this processing instruction.
    #
    # Processing instruction don't have attributes, their content is treated as a raw string value. We need to parse
    # it as an Element to gain programmatic access to the attributes.
    #
    def to_element
      document.parse("<#{name} #{content}/>")[0]
    end
  end
end
