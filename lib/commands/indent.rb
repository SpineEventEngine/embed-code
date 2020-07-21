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

# Finds the maximal common indentation of the given lines.
#
# If all the given lines are empty, contain only whitespace, or there are no lines at all,
# returns zero.
#
# @param lines an array of lines which may or may not have leading whitespaces
# @return the number of leading whitespaces in all the lines except for the empty ones
def max_common_indentation(lines)
  indent = Float::INFINITY
  lines.each do |line|
    unless line.strip.empty?
      spaces = line[/^ */].size
      if spaces < indent
        indent = spaces
      end
    end
  end
  indent == Float::INFINITY ? 0 : indent
end
