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

package cli

import (
	"errors"
	"flag"
	"fmt"
	"os"
	"slices"
	"strings"

	"embed-code/embed-code-go/analyzing"
	"embed-code/embed-code-go/configuration"
	"embed-code/embed-code-go/embedding"
	"embed-code/embed-code-go/fragmentation"

	"gopkg.in/yaml.v3"
)

// User-specified embed-code Config.
//
// СodeRoot — a path to a root directory with code files.
//
// DocsPath — a path to a root directory with docs files.
//
// CodeIncludes — a string with comma-separated patterns for filtering the code files
// to be considered.
// Directories are never matched by these patterns.
// For example, "**/*.java,**/*.gradle".
// The default value is "**/*.*".
//
// DocIncludes — a string with comma-separated patterns for filtering files
// in which we should look for embedding instructions.
// The patterns are resolved relatively to the `documentation_root`.
// Directories are never matched by these patterns.
// For example, "docs/**/*.md,guides/*.html".
// The default value is "**/*.md,**/*.html".
//
// FragmentsPath — a directory where fragmented code is stored. A temporary directory that should
// not be tracked in VCS. The default value is: "./build/fragments".
//
// Separator — a string that's inserted between multiple partitions of a single fragment.
// The default value is "...".
//
// ConfigPath — a path to a yaml configuration file which contains the roots.
//
// Mode — defines the mode of embed-code execution.
type Config struct {
	CodePath      string `yaml:"code-path"`
	DocsPath      string `yaml:"docs-path"`
	CodeIncludes  string `yaml:"code-includes"`
	DocIncludes   string `yaml:"doc-includes"`
	FragmentsPath string `yaml:"fragments-path"`
	Separator     string `yaml:"separator"`
	ConfigPath    string
	Mode          string
}

const (
	ModeCheck   = "check"
	ModeEmbed   = "embed"
	ModeAnalyze = "analyze"
)

//
// Public functions
//

// Checks documentation to be up-to-date with code files. Raises UnexpectedDiffError if not.
//
// config — a configuration for checking code samples.
func CheckCodeSamples(config configuration.Configuration) {
	err := fragmentation.WriteFragmentFiles(config)
	if err != nil {
		panic(err)
	}
	embedding.CheckUpToDate(config)
}

// Embeds code fragments in documentation files.
//
// config — a configuration for embedding.
func EmbedCodeSamples(config configuration.Configuration) {
	err := fragmentation.WriteFragmentFiles(config)
	if err != nil {
		panic(err)
	}
	embedding.EmbedAll(config)
}

// Analyzes code fragments in documentation files.
//
// config — a configuration for embedding.
func AnalyzeCodeSamples(config configuration.Configuration) {
	err := fragmentation.WriteFragmentFiles(config)
	if err != nil {
		panic(err)
	}
	analyzing.AnalyzeAll(config)
	fragmentation.CleanFragmentFiles(config)
}

// Reads user-specified args from the command line.
//
// Returns an Config struct filled with the corresponding args.
func ReadArgs() Config {
	codePath := flag.String("code-path", "", "a path to a root directory with code files")
	docsPath := flag.String("docs-path", "", "a path to a root directory with docs files")
	codeIncludes := flag.String("code-includes", "**/*.*",
		"a comma-separated string of glob patterns for code files to include")
	docIncludes := flag.String("doc-includes", "**/*.md,**/*.html",
		"a comma-separated string of glob patterns for docs files to include")
	fragmentsPath := flag.String("fragments-path", "./build/fragments",
		"a path to a directory where fragmented code is stored")
	separator := flag.String("separator", "...",
		"a string that's inserted between multiple partitions of a single fragment")
	configPath := flag.String("config-path", "", "a path to a yaml configuration file")
	mode := flag.String("mode", "",
		"a mode of embed-code execution, which can be 'check' or 'embed'")

	flag.Parse()

	return Config{
		CodePath:      *codePath,
		DocsPath:      *docsPath,
		CodeIncludes:  *codeIncludes,
		DocIncludes:   *docIncludes,
		FragmentsPath: *fragmentsPath,
		Separator:     *separator,
		ConfigPath:    *configPath,
		Mode:          *mode,
	}
}

// Checks the validity of provided userArgs and returns an error message if any of the validation
// rules are broken. If everything is ok, returns an empty string.
//
// userArgs — a struct with user-provided args.
func ValidateConfig(config Config) error {
	err := validateMode(config.Mode)
	if err != nil {
		return err
	}

	return validateIfConfigSetWithFileOrArgs(config)
}

// Performs several checks to ensure that the necessary configuration values are present.
// Also checks for the existence of the config file.
//
// path — a path to a yaml configuration file.
//
// Returns validation message. If everything is ok, returns an empty string.
func ValidateConfigFile(path string) error {
	exists, err := isFileExist(path)
	if err != nil {
		return err
	}
	if !exists {
		return errors.New("config file is not exist")
	}

	configFields := readConfigFields(path)
	if isEmpty(configFields.CodePath) || isEmpty(configFields.DocsPath) {
		return errors.New("config must include both code-path and docs-path fields")
	}

	return nil
}

// Fills args with the values read from config file.
//
// args — an Config struct with user-provided args.
//
// Returns filled Config.
func FillArgsFromConfigFile(args Config) (Config, error) {
	exists, err := isFileExist(args.ConfigPath)
	if err != nil {
		return Config{}, err
	}
	if !exists {
		return Config{}, errors.New("config file is not exist")
	}

	configFields := readConfigFields(args.ConfigPath)
	args.CodePath = configFields.CodePath
	args.DocsPath = configFields.DocsPath

	if isNotEmpty(configFields.CodeIncludes) {
		args.CodeIncludes = configFields.CodeIncludes
	}
	if isNotEmpty(configFields.DocIncludes) {
		args.DocIncludes = configFields.DocIncludes
	}
	if isNotEmpty(configFields.FragmentsPath) {
		args.FragmentsPath = configFields.FragmentsPath
	}
	if isNotEmpty(configFields.Separator) {
		args.Separator = configFields.Separator
	}

	return args, nil
}

// Generates and returns a configuration based on provided userArgs.
//
// userArgs — a struct with user-provided args.
func BuildEmbedCodeConfiguration(userArgs Config) configuration.Configuration {
	embedCodeConfig := configuration.NewConfiguration()
	embedCodeConfig.CodeRoot = userArgs.CodePath
	embedCodeConfig.DocumentationRoot = userArgs.DocsPath

	if isNotEmpty(userArgs.CodeIncludes) {
		embedCodeConfig.CodeIncludes = parseListArgument(userArgs.CodeIncludes)
	}
	if isNotEmpty(userArgs.DocIncludes) {
		embedCodeConfig.DocIncludes = parseListArgument(userArgs.DocIncludes)
	}
	if isNotEmpty(userArgs.FragmentsPath) {
		embedCodeConfig.FragmentsDir = userArgs.FragmentsPath
	}
	if isNotEmpty(userArgs.Separator) {
		embedCodeConfig.Separator = userArgs.Separator
	}

	return embedCodeConfig
}

//
// Private functions
//

// Returns a list of strings from given comma-separated string listArgument.
func parseListArgument(listArgument string) []string {
	splitArgs := strings.Split(listArgument, ",")
	parsedArgs := make([]string, 0)
	for _, v := range splitArgs {
		if trimmed := strings.TrimSpace(v); trimmed != "" {
			parsedArgs = append(parsedArgs, trimmed)
		}
	}

	return parsedArgs
}

// Reads the file from provided configFilePath and returns a ConfigFields struct.
//
// configFilePath — a path to a yaml configuration file.
//
// Returns a filled ConfigFields struct.
func readConfigFields(configFilePath string) Config {
	content, err := os.ReadFile(configFilePath)
	if err != nil {
		panic(err)
	}

	configFields := Config{}
	err = yaml.Unmarshal(content, &configFields)
	if err != nil {
		panic(err)
	}

	return configFields
}

func validateMode(mode string) error {
	isModeSet := isNotEmpty(mode)
	if !isModeSet {
		return errors.New("mode must be set")
	}

	validModes := []string{ModeEmbed, ModeAnalyze, ModeCheck}
	isValidMode := slices.Contains(validModes, mode)

	if !isValidMode {
		return fmt.Errorf("invalid value for mode. it must be one of — %s, %s or %s",
			ModeEmbed, ModeCheck, ModeAnalyze)
	}

	return nil
}

func validateIfConfigSetWithFileOrArgs(config Config) error {
	isConfigSet, err := validatePathIfSet(config.ConfigPath)
	if err != nil {
		return err
	}
	isCodePathSet, err := validatePathIfSet(config.CodePath)
	if err != nil {
		return err
	}
	isDocsPathSet, err := validatePathIfSet(config.DocsPath)
	if err != nil {
		return err
	}

	isRootsSet := isCodePathSet && isDocsPathSet
	isOneOfRootsSet := isCodePathSet || isDocsPathSet
	isOptionalParamsSet := validateIfOptionalParamsAreSet(config)

	if isConfigSet && (isOneOfRootsSet || isOptionalParamsSet) {
		return errors.New(
			"config path cannot be set when code-path, docs-path or optional params are set")
	}
	if isOneOfRootsSet && !isRootsSet {
		return errors.New(
			"if one of code-path and docs-path is set, the another one must be set as well")
	}
	if !(isRootsSet || isConfigSet) {
		return errors.New("embed code should be used with either config-path or both " +
			"code-path and docs-path being set")
	}

	return nil
}

func validateIfOptionalParamsAreSet(config Config) bool {
	isCodeIncludesSet := isNotEmpty(config.CodeIncludes)
	isDocIncludesSet := isNotEmpty(config.DocIncludes)
	isSeparatorSet := isNotEmpty(config.Separator)
	isFragmentPathSet := isNotEmpty(config.FragmentsPath)

	return isCodeIncludesSet || isDocIncludesSet || isFragmentPathSet || isSeparatorSet
}

// Reports whether path is set or not. If it is set, checks if such path exists.
func validatePathIfSet(path string) (bool, error) {
	isPathSet := isNotEmpty(path)
	if isPathSet {
		exists, err := isDirExist(path)
		if err != nil {
			// Since the path is set, returning true even we have an error.
			return true, err
		}
		if !exists {
			return true, errors.New("config file is not exist")
		}
		return true, nil
	}

	return false, nil
}

func isFileExist(filePath string) (bool, error) {
	exists, info, err := validateIfPathExists(filePath)
	if err != nil {
		return false, err
	}
	if exists {
		if info.IsDir() {
			return false, fmt.Errorf("%s is a directory, the file was expected", filePath)
		}

		return true, nil
	}

	return false, nil
}

func isDirExist(path string) (bool, error) {
	exists, info, err := validateIfPathExists(path)
	if err != nil {
		return false, err
	}
	if exists {
		if info.IsDir() {
			return true, nil
		}
		return false, fmt.Errorf("%s is a file, the directory was expected", path)
	}

	return false, nil
}

func validateIfPathExists(path string) (bool, os.FileInfo, error) {
	info, err := os.Stat(path)

	if err != nil {
		if os.IsNotExist(err) {
			return false, nil, fmt.Errorf("the path %s is not exist", path)
		}
		return false, nil, err
	}

	return true, info, nil
}

func isNotEmpty(s string) bool {
	return !isEmpty(s)
}

func isEmpty(s string) bool {
	return strings.TrimSpace(s) == ""
}
