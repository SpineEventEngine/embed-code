# embed-code

This is a custom Jekyll [subcommand](https://jekyllrb.com/docs/plugins/commands/) that embeds code samples into 
Markdown files:

```
bundle exec jekyll embedCodeSamples
```

## Usage

### In Markdown

To add a new code sample, add the following construct to the Markdown file:

<pre>
&lt;?embed-code file=&quot;java/lang/String.java&quot; 
             fragment=&quot;constructors&quot; ?&gt;
```java
```   
</pre>

This is an `<?embed-code?>` tag followed by a code fence (with the language you need). The code fence may be empty, 
or not empty, the command will overwrite it automatically. 

#### Supported Attributes

 * **file.** A path to the code file relative to the code root, specified in the configuration.
 * **fragment.** A name of the fragment in the specified file. Omit documentation fragment if you want to embed 
 the whole file.

### In Code

The whole file can be embedded without any additional effort.

If you want to embed only a relevant portion of the file, mark it up into fragments like this:

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

The fragments mark-up won't be rendered into Markdown.

#### Fragment Naming

You may use any name for your fragments, just omit double quotes (`"`) and symbols forbidden in XML.

#### More on Fragments

A fragment may appear in the file multiple times. When rendered, the occurrences of the fragment are
joined together and interlaid with a special interlaying text (see [Configuration](#configuration)).

Here is an example of how a re-occurring fragment is rendered.

**Code:**

```java
public final class String
    implements java.io.Serializable, Comparable<String>, CharSequence {

    // #docfragment "standard-object-methods"
    public int hashCode() {
        // ...
        return hash;
    }
    // #enddocfragment "standard-object-methods"
    
    /* here goes irrelevant code */

    // #docfragment "standard-object-methods"
    public boolean equals(Object anObject) {
        // ...
        return false;
    }
    // #enddocfragment "standard-object-methods"

    /* here goes more irrelevant code */

    // #docfragment "standard-object-methods"
    public String toString() {
        return this;
    }
    // #enddocfragment "standard-object-methods"
}
```

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

You can start (or end) multiple fragments on a single line. Also they can overlap:

```java
public final class String
    implements java.io.Serializable, Comparable<String>, CharSequence {

    // #docfragment "standard-object-methods", "all-methods"
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
    // #enddocfragment "standard-object-methods"

    public boolean startsWith(String prefix, int toffset) {
        // ...
        return true;
    }
    // #enddocfragment "all-methods"
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

By default, the command recursively reads all files from `_samples` directory and embeds them into
Markdown files found in `./docs` directory.

You can change these settings in the very place they're defined: [../_config.yml]()

For example:
```yaml
embed_code:
  code_root: ./_samples                   # The directory that will be recursively scanned for sample code files.
  code_includes: "**/*.java,**/*.gradle"  # The rules defining which code files to consider.
  documentation_root: ./docs              # The directory with the Markdown to be processed.
  fragments_dir: .fragments               # The directory where intermediary results of the plug-in are written.
  interlayer: "..."                       # A piece of text to be inserted between occurrences of the same fragment.
```


### Plug-in details

This software is written in Ruby as it's a plug-in for a Ruby-based Jekyll. While Ruby may not be familiar to you, 
this plug-in consists of the trivial string and file manipulations which should be easy to understand. 

### IDEA Live Template

```
// #docfragment "$NAME$"
// #enddocfragment "$NAME$"
```
