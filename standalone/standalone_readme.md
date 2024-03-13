To create .exe you should:
1. Make sure you have Ruby installed (https://www.ruby-lang.org/en/downloads)
   ```bash
   ruby -v
   ```
2. Make sure you have bundle installed:
   ```bash
   gem install bundle
   ```
3. Install all dependencies
   ```bash
   bundle install
   ```
4. Install ocran (https://github.com/Largo/ocran) 
   ```bash
   gem install ocran
   ```
5. Run 
   ```bash
   ocran <scriptname>.rb
   ```

Take a note that the ocran runs your script on start. You can disable this behaviour with setting flag __--no-dep-run__. But in this case you cannot be sure that all your code and dependencies will be included in a binary file. 
Better solution is to support default launching of your script.
For example, if your script relies on command line arguments, you may provide default values for them.