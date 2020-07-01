# embed-code

This is a Jekyll [subcommand](https://jekyllrb.com/docs/plugins/commands/) that embeds code samples
into documentation files.

## Installation

To add the plugin to your Jekyll project, add the Gem to your `Gemfile`:
```Gemfile
gem 'embed-code', :git => 'https://github.com/SpineEventEngine/embed-code', :group => :jekyll_plugins
```

Now install the dependencies:
```
bundle install
```

_Note:_ Fetching a Gem from Git is a feature of Bundler. Right now, this cannot be replicated with
the standard `gem` tool. Also, we don't publish `embed-code` into any Gem repository _yet_.

## Usage

```
bundle exec jekyll embedCodeSamples
```

### In Markdown

#### Named fragments

To add a new code sample, add the following construct to the Markdown file:

<pre>
&lt;?embed-code file=&quot;java/lang/String.java&quot;
             fragment=&quot;constructors&quot; ?&gt;
```java
```   
</pre>

This is an `<?embed-code?>` tag followed by a code fence (with the language you need). The content
of the code fence does not matter — the command will overwrite it automatically.

The `file` attribute specifies the path to the code file relative to the code root, specified in
the configuration. The `fragment` attribute specifies the name of the code fragment to embed. Omit
this attribute to embed the whole file or to use glob patterns.

#### Pattern fragments

Alternatively, the `<?embed-code?>` tag may have the following form:
<pre>
&lt;?embed-code file=&quot;java/lang/String.java&quot;
             start=&quot;*class Hello*&quot;
             end=&quot;}*&quot;?&gt;
```java
```   
</pre>

The difference is that here fragment is specified by a pair of glob-style patterns. The patterns
match the first and the last lines of the desired code fragment. Any of the patterns may be skipped.
In such a case, the fragment starts at the beginning or ends at the end of the code file.

The pattern syntax supports basic glob constructs:
 - `?` — one arbitrary symbol;
 - `*` — zero, one, or many arbitrary symbols;
 - `[set]` — one symbol from the given set (equivalent to `[set]` in regular expressions).

### In Code

The whole file can be embedded without any additional effort.

You can mark up the code file to select named fragments like this:

```java
public final class String
    implements java.io.Serializable, Comparable<String>, CharSequence {
    
    // #docfragment "constructors"
    public String() {
        this.value = new char[0];
    }

    public String(String original) {
        this.value = original.value;
        this.hash = original.hash;
    }

    public String(char value[]) {
        this.value = Arrays.copyOf(value, value.length);
    }
    // #enddocfragment "constructors"
}
```

The `#docfragment` and `#enddocfragment` tags won't be copied into the resulting code fragment.

#### Fragment Naming

You may use any name for your fragments, just omit double quotes (`"`) and symbols forbidden in XML.

#### More on Fragments

A fragment may consist of one or several pieces declared in a single file. When rendered, the pieces
which belong to a single fragment are joined together. One may also specify the text inserted in
each joint point (see [Configuration](#configuration) for the corresponding parameter).

Here is an example of how a re-occurring fragment is rendered.

**Code:**

```java
public final class String
    implements java.io.Serializable, Comparable<String>, CharSequence {

    // #docfragment "Standard Object methods"
    public int hashCode() {
        // ...
        return hash;
    }
    // #enddocfragment "Standard Object methods"
    
    /* here goes irrelevant code */

    // #docfragment "Standard Object methods"
    public boolean equals(Object anObject) {
        // ...
        return false;
    }
    // #enddocfragment "Standard Object methods"

    /* here goes more irrelevant code */

    // #docfragment "Standard Object methods"
    public String toString() {
        return this;
    }
    // #enddocfragment "Standard Object methods"
}
```

As the name of each fragment is put into quotes, space symbols may be used. So one may use the
natural language (e.g. "My favorite fragment here!") instead of `CamelCase`, `snake_case`, or
`kebab-case` (e.g. "my-favourite-fragment-here-exclamation-mark").

**Result:**

```java
public int hashCode() {
    // ...
    return hash;
}
...
public boolean equals(Object anObject) {
    // ...
    return false;
}
...
public String toString() {
    return this;
}
```

You can start (or end) multiple fragments on a single line. Also, they can overlap:

```java
public final class String
    implements java.io.Serializable, Comparable<String>, CharSequence {

    // #docfragment "Standard Object methods", "All methods"
    public int hashCode() {
        // ...
        return hash;
    }

    public boolean equals(Object anObject) {
        // ...
        return false;
    }

    public String toString() {
        return this;
    }
    // #enddocfragment "Standard Object methods"

    public boolean startsWith(String prefix, int toffset) {
        // ...
        return true;
    }
    // #enddocfragment "All methods"
}
``` 

The fragments can be used in other languages too:
```html
<html lang="en">
<body>
<!-- #docfragment "html-only", "asd" -->
<span class="counter" id="counter"></span>
<!-- #enddocfragment "html-only" -->
</body>
</html>
```

### Configuration

In order for the command to work, you need to specify at least two configurations params:
 - `code_root` — the directory where all the embedded code resides;
 - `documentation_root` — the directory where all the docs which need embedding reside.

Those parameters should be specified via the Jekyll `_config.yml` file.

For example:
```yaml
embed_code:
  code_root: ./_samples
  documentation_root: ./docs

  # Optional params:
  code_includes: ["**/*.java", "**/*.gradle"]
  doc_includes:  ["docs/*.md", "docs/*.html"]
  fragments_dir: ".fragments"
  separator: "..."
```

Other command configuration parameters include:
 - `code_includes` — a list of glob patterns defining which code files to consider. By default,
   all files (`**/*`).
 - `doc_includes` — a list of glob patterns defining which doc files to consider. By default,
   Markdown and HTML files (`**/*.md`, `**/*.html`).
 - `fragments_dir` — a temporary directory for fragment files. The command extracts the code
   fragments files and stores them in a temporary dir. Consider adding this directory to
   `.gitignore`. By default, `./.fragments`
 - `separator` — a string which separates partitions of a single fragment in the resulting embedded
   code. See [fragment doc](#more-on-fragments) for more. The separator is automatically appended
   with a new line symbol. By default, `...`.

## Development

This software is written in Ruby as a plug-in for [Jekyll](https://jekyllrb.com/).

The minimal required version of Ruby is `2.5` (constrained by Jekyll). However, it is recommended to
use Ruby `2.7` or above, as it has security fixes for issues in `2.5`.

## Testing

Before running tests, make sure to:

1. Install Ruby. Check installation by running:
    ```
    ruby -v
    ```
2. Install Bundler:
    ```
    gem install bundler
    ```
3. Install project dependencies:
    ```
    bundle install
    ```

Now, run tests using the `test/run.rb` script:
```
ruby ./test/run.rb
```

When launched on Travis CI, the script also collects and uploads code coverage data.

### IDEA Live Template

```
// #docfragment "$NAME$"
// #enddocfragment "$NAME$"
```
