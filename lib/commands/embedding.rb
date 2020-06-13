require 'nokogiri'
require_relative('configuration')
require_relative('embedding_instruction')

module Jekyll
  module Commands

    # Finds embedding instructions and in the Markdown file and processes them.
    #
    class EmbeddingProcessor

      # @param [String] markdown_file the path to the markdown file
      def initialize(markdown_file = "")
        @markdown_file = markdown_file
      end

      # Embeds sample code fragments in the documentation file.
      #
      # This method looks for appearances of `EmbeddingInstruction` followed by the code fence. The code fence
      # may be not empty, in which case its content will be overwritten.
      #
      # If the file doesn't contain any embedding statements, it is not changed.
      #
      def embed
        context = MarkdownParsingContext.new(@markdown_file)

        current_state = :START
        while current_state != :FINISH
          accepted = false
          TRANSITIONS[current_state].each do |next_state|
            transition = STATE_TO_TRANSITION[next_state]
            if transition.recognize(context)
              current_state = next_state
              transition.accept(context)
              accepted = true
              break
            end
          end
          unless accepted
            raise StandardError.new "Failed to parse the file"
          end
        end

        if context.file_contains_embedding
          IO.write(@markdown_file, context.result.join(""))
        end
      end
    end

    class MarkdownParsingContext
      def initialize(markdown_file)
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

      attr_reader :embedding
      attr_reader :file_contains_embedding
      attr_reader :source
      attr_accessor :result
      attr_accessor :code_fence_started
      attr_accessor :code_fence_indentation
      attr_accessor :fragments_dir
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

      def accept(context)
        instruction_body = []
        until context.reached_eof
          instruction_body.push(context.current_line)
          instruction = EmbeddingInstruction.from_xml(instruction_body.join(""))
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
          raise StandardError.new "Failed to parse an embedding instruction"
        end
      end
    end

    # A regular line in a Markdown, with no meaning for this plug-in.
    class RegularLine
      def recognize(context)
        true
      end

      def accept(context)
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

      def accept(context)
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

      def accept(context)
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
      end
    end

    # A line between the code-fences.
    #
    class CodeSampleLine
      def recognize(context)
        !context.reached_eof and context.code_fence_started
      end

      def accept(context)
        context.to_next_line
      end
    end

    # EOF
    class Finish
      def recognize(context)
        context.reached_eof
      end

      def accept(context)
        # No op.
      end
    end

    STATE_TO_TRANSITION = {
        :REGULAR_LINE => RegularLine.new,
        :EMBEDDING_INSTRUCTION => EmbedInstructionToken.new,
        :CODE_FENCE_START => CodeFenceStart.new,
        :CODE_FENCE_END => CodeFenceEnd.new,
        :CODE_SAMPLE_LINE => CodeSampleLine.new,
        :FINISH => Finish.new
    }

    # A simple grammar of the Markdown file that consists of the regular lines and the embedding instructions followed
    # by the code fences (empty or non-empty).
    TRANSITIONS = {
        :START => [:FINISH, :EMBEDDING_INSTRUCTION, :REGULAR_LINE],
        :REGULAR_LINE => [:FINISH, :EMBEDDING_INSTRUCTION, :REGULAR_LINE],
        :EMBEDDING_INSTRUCTION => [:CODE_FENCE_START],
        :CODE_FENCE_START => [:CODE_FENCE_END, :CODE_SAMPLE_LINE],
        :CODE_SAMPLE_LINE => [:CODE_FENCE_END, :CODE_SAMPLE_LINE],
        :CODE_FENCE_END => [:FINISH, :EMBEDDING_INSTRUCTION, :REGULAR_LINE]
    }
  end
end
