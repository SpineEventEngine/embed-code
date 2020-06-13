require_relative('fragmentation')

module Jekyll
  module Commands

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
      STATEMENT = '<?embed-code'
      TAG_NAME = 'embed-code'

      def initialize(values)
        @code_file = values['file']
        @fragment = values['fragment']
      end

      # Reads the instruction from the '<?embed-code?>' XML tag (technically, it's a processing instruction, not a tag).
      #
      def self.from_xml(line)
        begin
          document = Nokogiri.XML(line)
          tag = document.at_xpath("//processing-instruction('#{TAG_NAME}')").to_element
          fields = tag.attributes.map { |name, value| [name, value.to_s] }.to_h
          return EmbeddingInstruction.new(fields)
        rescue
          return nil
        end
      end

      # Reads the specified fragment from the code.
      #
      # If the fragment appears more than once in a file, the occurrences are interlayed with Configuration::interlayer.
      #
      def content
        interlayer = Configuration.instance.interlayer
        lines = []
        read_fragments.each do |content|
          if lines.any?
            lines.push(interlayer + "\n")
          end
          lines += content
        end
        lines
      end

      private

      def read_fragments
        if @fragment
          result = []
          (0..100).each do |fragment_index|
            fragment_content = FragmentFile.new(@code_file, @fragment, fragment_index).content
            if fragment_content
              result.push(fragment_content)
            else
              break
            end
          end
          result
        else
          fragment_file = FragmentFile.new(@code_file, Fragment::DEFAULT_FRAGMENT, nil)
          [fragment_file.content]
        end
      end
    end
  end

  # Extends Nokogiri's class with 'to_element' method.
  #
  class Nokogiri::XML::ProcessingInstruction

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