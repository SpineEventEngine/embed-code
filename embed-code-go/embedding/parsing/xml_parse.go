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

package parsing

import (
	"embed-code/embed-code-go/configuration"
	"encoding/xml"
	"fmt"
)

const xmlStringHeader string = "embed-code"

// Item needed for xml.Unmarshal parsing. The fields are filling up during the parsing.
//
// XMLName — a name of the tag in XML line.
//
// Attrs — a list of xml.Attr. The xml.Attr contains both names and values of attributes.
type Item struct {
	XMLName xml.Name
	Attrs   []xml.Attr `xml:",any,attr"`
}

// FromXML reads the instruction from the '<embed-code>' XML tag and creates new Instruction.
//
// line — a line which contains '<embed-code>' XML tag.
// For example: '<embed-code file="org/example/Hello.java" fragment="Hello class"/>'.
// The line can also contain closing tag:
// '<embed-code file=\"org/example/Hello.java\" fragment=\"Hello class\"></embed-code>'.
// The following parameters are currently supported:
//   - file — a mandatory relative path to the file with the code;
//   - fragment — an optional name of the particular fragment in the code. If no fragment
//     is specified, the whole file is embedded;
//   - start — an optional glob-like pattern. If specified, lines before the matching one
//     are excluded;
//   - end — an optional glob-like pattern. If specified, lines after the matching one are excluded.
//
// config — a Configuration with all embed-code settings.
//
// Returns an error if the paring of XML instruction failed.
func FromXML(line string, config configuration.Configuration) (Instruction, error) {
	fields, err := ParseXMLLine(line)
	if err != nil {
		return Instruction{}, err
	}

	return NewInstruction(fields, config)
}

// ParseXMLLine parses given XML-encoded xmlLine and returns attributes data as key-value pairs.
//
// xmlLine — an XML-encoded line.
//
// Returns a map of key-value pairs. If the provided line is not valid, returns an error.
func ParseXMLLine(xmlLine string) (map[string]string, error) {
	var root Item
	err := xml.Unmarshal([]byte(xmlLine), &root)
	if err != nil {
		return map[string]string{}, err
	}

	if root.XMLName.Local != xmlStringHeader {
		return map[string]string{},
			fmt.Errorf("the provided line's header is not 'embed-code':\n%s", xmlLine)
	}

	attributes := make(map[string]string)
	for _, subItem := range root.Attrs {
		attributes[subItem.Name.Local] = subItem.Value
	}

	return attributes, nil
}