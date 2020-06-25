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
  create_configuration(true)
end

def config
  create_configuration(false)
end

def build_instruction(file_name, fragment = nil)
  fragment_attr = fragment ? "fragment=\"#{fragment}\"" : ''
  "<?embed-code file=\"#{file_name}\" #{fragment_attr}?>"
end

private

def create_configuration(prepared_fragments)
  fragments_dir = prepared_fragments ? './test/prepared-fragments' : './test/fragments'
  # noinspection RubyStringKeysInHashInspection
  yaml_like_hash = {
    'embed_code' => {
      'code_root' => './test/code',
      'fragments_dir' => fragments_dir,
      'documentation_root' => './'
    }
  }
  Jekyll::Commands::Configuration.new(yaml_like_hash)
end
