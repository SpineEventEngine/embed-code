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

// Splits the given file into fragments.
//
// The fragments are named parts of the file that are surrounded by "fragment brackets":
// ```
//
//	class HelloWorld {
//	    // #docfragment main_method
//	    public static void main(String[] argv) {
//	        // #docfragment printing
//	        System.out.println("Hello World");
//	        // #enddocfragment printing
//	    }
//	    // #enddocfragment main_method
//	}
//
// ```
//
// Fragments with the same name may appear multiple times in the same document.
//
// Even if no fragments are defined explicitly, the whole file is always a fragment on its own.
package fragmentation

import (
	"bufio"
	"embed-code/embed-code-go/configuration"
	"fmt"
	"os"
	"path/filepath"
)

const (
	FragmentStart = "#docfragment"
	FragmentEnd   = "#enddocfragment"
)

type Fragmentation struct {
	Configuration configuration.Configuration
	SourcesRoot   string
	CodeFile      string
}

// TODO: handle the errors
func NewFragmentation(
	codeFileRelative string,
	config configuration.Configuration,
) Fragmentation {

	fragmentation := Fragmentation{}

	sourcesRootRelative := config.CodeRoot

	absoluteSourcesRoot, err := filepath.Abs(sourcesRootRelative)
	fragmentation.SourcesRoot = absoluteSourcesRoot
	if err != nil {
		fmt.Println(err)
	}

	absoluteCodeFile, err := filepath.Abs(codeFileRelative)
	fragmentation.CodeFile = absoluteCodeFile
	if err != nil {
		fmt.Println(err)
	}

	fragmentation.Configuration = config

	return fragmentation
}

// @return (content, fragments) a refined content of the file to be cut into fragments, and the Fragments
func (fragmentation Fragmentation) fragmentize() ([]string, map[string]Fragment) {
	fragmentBuilders := make(map[string]FragmentBuilder)
	var contentToRender []string

	file, err := os.Open(fragmentation.CodeFile)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		contentToRender, fragmentBuilders = fragmentation.parseLine(line, contentToRender, fragmentBuilders)
	}

	fragments := make(map[string]Fragment)
	for k, v := range fragmentBuilders {
		fragments[k] = v.Build()
	}
	fragments[DefaultFragment] = CreateDefaultFragment()

	return contentToRender, fragments

}

func (fragmentation Fragmentation) parseLine(line string, contentToRender []string, fragmentBuilders map[string]FragmentBuilder) ([]string, map[string]FragmentBuilder) {
	cursor := len(contentToRender)

	fragmentStarts := getFragmentStarts(line)
	fragmentEnds := getFragmentEnds(line)

	if len(fragmentStarts) > 0 {
		for _, fragmentName := range fragmentStarts {
			builder := FragmentBuilder{FileName: fragmentation.CodeFile, Name: fragmentName}
			fragment, exists := fragmentBuilders[fragmentName]
			if !exists {
				fragmentBuilders[fragmentName] = builder
				fragment = builder
			}
			fragment.AddStartPosition(cursor)
		}
	} else if len(fragmentEnds) > 0 {
		for _, fragmentName := range fragmentEnds {
			if fragment, exists := fragmentBuilders[fragmentName]; exists {
				fragment.AddEndPosition(cursor - 1)
			} else {
				panic(fmt.Sprintf("Cannot end the fragment `%s` as it wasn't started.", fragmentName))
			}
		}
	} else {
		contentToRender = append(contentToRender, line)
	}
	return contentToRender, fragmentBuilders
}

func (fragmentation Fragmentation) targetDirectory() string {
	fragmentsDir := fragmentation.Configuration.FragmentsDir
	codeRoot := filepath.Clean(fragmentation.Configuration.CodeRoot)
	relativeFile, err := filepath.Rel(codeRoot, fragmentation.CodeFile)
	if err != nil {
		panic(fmt.Sprintf("Error calculating relative path: %v", err))
	}
	subTree := filepath.Dir(relativeFile)
	return filepath.Join(fragmentsDir, subTree)
}

// WriteFragments serializes fragments to the output directory.
//
// Keeps the original directory structure relative to the sourcesRoot. That is,
// `SRC/src/main` becomes `OUT/src/main`.
func (fragmentation Fragmentation) WriteFragments() {
	allLines, fragments := fragmentation.fragmentize()

	ensureDirExists(fragmentation.targetDirectory())

	for _, fragment := range fragments {
		fragmentFile := NewFragmentFileFromAbsolute(fragmentation.CodeFile, fragment.Name, fragmentation.Configuration)
		fragment.WriteTo(fragmentFile, allLines, fragmentation.Configuration)
	}
}

func WriteFragmentFiles(configuration configuration.Configuration) {
	includes := configuration.CodeIncludes
	codeRoot := configuration.CodeRoot
	for _, rule := range includes {
		pattern := fmt.Sprintf("%s/%s", codeRoot, rule)
		codeFiles, _ := filepath.Glob(pattern)
		for _, codeFile := range codeFiles {
			if shouldFragmentize(codeFile) {
				fragmentation := NewFragmentation(codeFile, configuration)
				fragmentation.WriteFragments()
			}
		}
	}
}