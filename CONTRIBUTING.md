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
