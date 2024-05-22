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

package embedding

import (
	"embed-code/embed-code-go/embedding/parsing"
	"fmt"
	"path/filepath"
)

// Describes an error which occurs if outdated files are found during the checking.
type EmbeddingError struct {
	Context       parsing.ParsingContext
	OriginalError error
}

func (embeddingErr EmbeddingError) Error() string {
	relativeMarkdownPath, err := filepath.Rel(
		embeddingErr.Context.Embedding.Configuration.DocumentationRoot,
		embeddingErr.Context.MarkdownFile)

	if err != nil {
		panic(embeddingErr)
	}

	return fmt.Sprintf("error: %s | %s — %s | %s",
		relativeMarkdownPath,
		embeddingErr.Context.Embedding.CodeFile,
		embeddingErr.Context.Embedding.Fragment,
		embeddingErr.OriginalError.Error())

}
