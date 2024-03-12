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

require('nokogiri')
require_relative('configuration')
require_relative('embedding_instruction')
require_relative('errors')


module EmbedCode

  # Finds embedding instructions and in the Markdown file and processes them.
  #
  class EmbeddingProcessor

    # @param [String] doc_file the path to the markdown file
    def initialize(doc_file, configuration)
      @doc_file = doc_file
      @configuration = configuration
    end

    def self.embed_all(configuration)
      documentation_root = configuration.documentation_root
      doc_patterns = configuration.doc_includes
      doc_patterns.each do |pattern|
        Dir.glob("#{documentation_root}/#{pattern}") do |documentation_file|
          EmbeddingProcessor.new(documentation_file, configuration).embed
        end
      end
    end

    def self.check_up_to_date(configuration)
      changed_files = find_changed_files configuration
      unless changed_files.empty?
        raise UnexpectedDiffError, changed_files
      end
    end

    private_class_method def self.find_changed_files(configuration)
      documentation_root = configuration.documentation_root
      doc_patterns = configuration.doc_includes
      changed_files = []
      doc_patterns.each do |pattern|
        Dir.glob("#{documentation_root}/#{pattern}") do |documentation_file|
          up_to_date = EmbeddingProcessor.new(documentation_file, configuration).up_to_date?
          unless up_to_date
            changed_files.append documentation_file
          end
        end
      end
      changed_files
    end

    # Embeds sample code fragments in the documentation file.
    #
    # This method looks for appearances of `EmbeddingInstruction` followed by the code fence.
    # The code fence  may be not empty, in which case its content will be overwritten.
    #
    # If the file doesn't contain any embedding statements, it is not changed.
    #
    def embed
      context = construct_embedding

      if context.file_contains_embedding && context.content_changed?
        IO.write(@doc_file, context.result.join(''))
      end
    end

    # Checks if the code fragments in the documentation file are up-to-date with the original
    # code examples.
    #
    # See +embed+ for updating the code samples.
    #
    def up_to_date?
      context = construct_embedding
      !context.content_changed?
    end

    private

    def construct_embedding
      context = ParsingContext.new(@doc_file)

      current_state = :START
      while current_state != :FINISH
        accepted = false
        TRANSITIONS[current_state].each do |next_state|
          transition = STATE_TO_TRANSITION[next_state]
          if transition.recognize(context)
            current_state = next_state
            transition.accept(context, @configuration)
            accepted = true
            break
          end
        end
        unless accepted
          raise StandardError, "Failed to parse the doc file `#{@doc_file}`. Context: #{context}"
        end
      end
      context
    end
  end

  class ParsingContext

    attr_reader :embedding
    attr_reader :file_contains_embedding
    attr_reader :source
    attr_reader :markdown_file
    attr_reader :line_index
    attr_accessor :result
    attr_accessor :code_fence_started
    attr_accessor :code_fence_indentation
    attr_accessor :fragments_dir

    def initialize(markdown_file)
      @markdown_file = markdown_file
      @source = File.readlines(markdown_file)
      @line_index = 0
      @result = []
      @embedding = nil
      @code_fence_started = false
      @code_fence_indentation = 0
      @file_contains_embedding = false
    end

    def current_line
      @source[@line_index]
    end

    def to_next_line
      @line_index += 1
    end

    def reached_eof
      @source.length <= @line_index
    end

    def embedding=(embedding)
      @embedding = embedding
      if embedding
        @file_contains_embedding = true
      end
    end

    def content_changed?
      for i in 0..@line_index
        return true if @source[i] != @result[i]
      end
      false
    end

    def to_s
      "ParsingContext[embedding=`#{@embedding}`, file=`#{@markdown_file}`, line=`#{@line_index}`]"
    end
  end

  # An embedding instruction.
  class EmbedInstructionToken

    def recognize(context)
      line = context.current_line
      if !context.embedding and !context.reached_eof and line.strip.start_with?(EmbeddingInstruction::STATEMENT)
        true
      else
        false
      end
    end

    def accept(context, configuration)
      instruction_body = []
      until context.reached_eof
        instruction_body.push(context.current_line)
        instruction = EmbeddingInstruction.from_xml(instruction_body.join(''), configuration)
        if instruction
          context.embedding = instruction
        end
        context.result.push(context.current_line)
        context.to_next_line
        if context.embedding
          break
        end
      end
      unless context.embedding
        raise StandardError, "Failed to parse an embedding instruction. Context: #{context}"
      end
    end
  end

  # A regular line in a Markdown, with no meaning for this plug-in.
  class RegularLine
    def recognize(_)
      true
    end

    def accept(context, _)
      context.result.push(context.current_line)
      context.to_next_line
    end
  end

  # A blank line dividing the embedding instruction and the code fence.
  #
  # The line may be used for formatting purposes. It is harmless and has no effect of the overall
  # tool behaviour.
  #
  class BlankLine
    def recognize(context)
      return false unless context.current_line.strip.empty?

      !context.reached_eof && !context.code_fence_started && context.embedding
    end

      def accept(context, _)
        context.result.push(context.current_line)
        context.to_next_line
      end
    end

  # An opening "bracket" of the code fence.
  class CodeFenceStart
    def recognize(context)
      if !context.reached_eof
        context.current_line.strip.start_with?('```')
      else
        false
      end
    end

    def accept(context, _)
      line = context.current_line
      context.result.push(line)
      context.code_fence_started = true
      leading_spaces = line[/\A */].size
      context.code_fence_indentation = leading_spaces
      context.to_next_line
    end
  end

  # A closing "bracket" of the code fence.
  class CodeFenceEnd
    def recognize(context)
      if !context.reached_eof
        indentation = ' ' * context.code_fence_indentation
        context.code_fence_started and context.current_line.start_with?(indentation + '```')
      else
        false
      end
    end

    def accept(context, _)
      line = context.current_line
      render_sample(context)
      context.result.push(line)
      context.embedding = nil
      context.code_fence_started = false
      context.code_fence_indentation = 0
      context.to_next_line
    end

    private

    def render_sample(context)
      context.embedding.content.each do |line|
        indentation = ' ' * context.code_fence_indentation
        context.result.push(indentation + line)
      end
    rescue StandardError => e
      puts "Failed to render #{context.markdown_file}:#{context.line_index}: #{e}"
    end
  end

  # A line between the code-fences.
  #
  class CodeSampleLine
    def recognize(context)
      !context.reached_eof and context.code_fence_started
    end

    def accept(context, _)
      context.to_next_line
    end
  end

  # EOF
  class Finish
    def recognize(context)
      context.reached_eof
    end

    def accept(_, _)
      # No op.
    end
  end

  STATE_TO_TRANSITION = {
      REGULAR_LINE: RegularLine.new,
      EMBEDDING_INSTRUCTION: EmbedInstructionToken.new,
      BLANK_LINE: BlankLine.new,
      CODE_FENCE_START: CodeFenceStart.new,
      CODE_FENCE_END: CodeFenceEnd.new,
      CODE_SAMPLE_LINE: CodeSampleLine.new,
      FINISH: Finish.new
  }.freeze

  # A simple grammar of the Markdown file that consists of the regular lines and the embedding instructions followed
  # by the code fences (empty or non-empty).
  TRANSITIONS = {
      START: [:FINISH, :EMBEDDING_INSTRUCTION, :REGULAR_LINE],
      REGULAR_LINE: [:FINISH, :EMBEDDING_INSTRUCTION, :REGULAR_LINE],
      EMBEDDING_INSTRUCTION: [:CODE_FENCE_START, :BLANK_LINE],
      BLANK_LINE: [:CODE_FENCE_START, :BLANK_LINE],
      CODE_FENCE_START: [:CODE_FENCE_END, :CODE_SAMPLE_LINE],
      CODE_SAMPLE_LINE: [:CODE_FENCE_END, :CODE_SAMPLE_LINE],
      CODE_FENCE_END: [:FINISH, :EMBEDDING_INSTRUCTION, :REGULAR_LINE]
  }.freeze
end
