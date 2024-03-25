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
	"os"
	"unicode/utf8"
)

// Reports whether the file stored at the filePath is UTF8-encoded
func IsFileUTF8Encoded(filePath string) (bool, error) {
	// Read the entire file into memory
	content, err := os.ReadFile(filePath)
	if err != nil {
		return false, err
	}

	// Check if the content contains valid UTF-8 characters
	isUTF8 := utf8.Valid(content)

	return isUTF8, nil
}

// Reports whether the file stored at the filePath is ASCII-encoded.
// If all the characters fall within the ASCII range (0 to 127), it’s likely an ASCII-encoded file.
func IsFileASCIIEncoded(filePath string) (bool, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return false, err
	}

	for _, char := range content {
		if char > 127 {
			return false, nil
		}
	}

	return true, nil
}

// Reports whether the file stored at the filePath is encoded as a text.
func IsEncodedAsText(filePath string) bool {
	isUTF8Encoded, err := IsFileUTF8Encoded(filePath)
	if err != nil {
		panic(err)
	}

	isASCIIEncoded, err := IsFileASCIIEncoded(filePath)
	if err != nil {
		panic(err)
	}

	return isUTF8Encoded || isASCIIEncoded
}
