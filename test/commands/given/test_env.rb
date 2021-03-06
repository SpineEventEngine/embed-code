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

def config_with_prepared_fragments
  config(true)
end

def config(prepared_fragments = false, code_includes = nil, doc_includes = nil)
  fragments_dir =
      prepared_fragments ? './test/resources/prepared-fragments' : './test/.fragments'
  # noinspection RubyStringKeysInHashInspection
  yaml_like_hash = {
      'embed_code' => {
          'code_root' => './test/resources/code',
          'fragments_dir' => fragments_dir,
          'documentation_root' => './test/.docs'
      }
  }
  unless code_includes.nil?
    yaml_like_hash['embed_code']['code_includes'] = code_includes
  end
  unless doc_includes.nil?
    yaml_like_hash['embed_code']['doc_includes'] = doc_includes
  end
  Jekyll::Commands::Configuration.new(yaml_like_hash)
end

def prepare_docs(source)
  FileUtils.copy_entry source, config.documentation_root
end

def build_instruction(file_name, fragment = nil, start_glob = nil, end_glob = nil, close_tag = false)
  fragment_attr = xml_attribute 'fragment', fragment
  start_attr = xml_attribute 'start', start_glob
  end_attr = xml_attribute 'end', end_glob

  "<embed-code file=\"#{file_name}\" #{fragment_attr} #{start_attr} #{end_attr}#{close_tag ? '></embed-code>' : '/>'}"
end

def delete_dir(path)
  if File.exist?(path)
    FileUtils.rm_r path, secure: true
  end
end

private

def xml_attribute(name, value)
  if value.nil?
    ''
  else
    "#{name}=\"#{value}\""
  end
end
