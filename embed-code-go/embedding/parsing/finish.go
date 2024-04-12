package parsing

import (
	"embed-code/embed-code-go/configuration"
)

// Represents the end of the file.
type Finish struct{}

//
// Public methods
//

// Reports whether the current line satisfies the transition.
//
// context — a context of the parsing process.
func (f Finish) Recognize(context ParsingContext) bool {
	return context.ReachedEOF()
}

// Accepts finish, there's no need to do anything.
//
// context — a context of the parsing process.
//
// config — a configuration of the embedding.
func (f Finish) Accept(context *ParsingContext, config configuration.Configuration) {
}