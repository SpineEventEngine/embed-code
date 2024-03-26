// Copyright 2024, TeamDev. All rights reserved.
//
// Redistribution and use in source and/or binary forms, with or without
// modification, must retain the above copyright notice and the following
// disclaimer.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package fragmentation

import (
	"regexp"
	"strconv"
	"strings"
)

// Returns the clean name from the given quoted name.
func UnquoteNameAndClean(name string) string {
	r, _ := regexp.Compile("\"(.*)\"")
	nameQuoted := r.FindString(name)
	nameCleaned, _ := strconv.Unquote(nameQuoted)
	return nameCleaned
}

// Look up for fragments' names from the given line.
//
// line is a line to search in.
//
// prefix is a user-defined indicator of a fragment, e.g. "#docfragment".
//
// Returns the list of the names found.
func Lookup(line string, prefix string) []string {
	if strings.Contains(line, prefix) {
		fragmentsStart := strings.Index(line, prefix) + len(prefix) + 1 // 1 for trailing space after the prefix
		unquotedFragmentNames := []string{}
		for _, fragmentName := range strings.Split(line[fragmentsStart:], ",") {
			quotedFragmentName := strings.Trim(fragmentName, "\n\t ")
			unquotedFragmentName := UnquoteNameAndClean(quotedFragmentName)
			unquotedFragmentNames = append(unquotedFragmentNames, unquotedFragmentName)
		}
		return unquotedFragmentNames
	} else {
		return []string{}
	}
}

// Finds all the names for the fragment's openings using the opening prefix.
//
// line is a line to search in.
//
// Returns the list of the names found.
func GetFragmentStarts(line string) []string {
	return Lookup(line, FragmentStart)
}

// Finds all the names for the fragment's endings using the ending prefix.
//
// line is a line to search in.
//
// Returns the list of the names found.
func GetFragmentEnds(line string) []string {
	return Lookup(line, FragmentEnd)
}