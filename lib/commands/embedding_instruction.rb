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

    # Reads the instruction from the '<?embed-code?>' XML instruction.
    #
    # @param [Object] line
    # @param [Configuration] configuration
    def self.from_xml(line, configuration)
      begin
        document = Nokogiri::XML(line)
        tag = document.at_xpath("//processing-instruction('#{TAG_NAME}')").to_element
      rescue StandardError => e
        puts e
        return nil
      end
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
      start_position = 0
      line_count = lines.length
      if @start
        until start_position >= line_count || File.fnmatch?(@start, lines[start_position])
          start_position += 1
        end
      end
      end_position = start_position
      if @end
        until end_position >= line_count || File.fnmatch(@end, lines[end_position])
          end_position += 1
        end
      else
        end_position = nil
      end
      required_lines = lines[start_position..end_position]
      indentation = find_minimal_indentation(required_lines)
      required_lines.map { |line| line[indentation..-1] }
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
