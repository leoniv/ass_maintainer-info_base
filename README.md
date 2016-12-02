# AssMaintainer::InfoBase


Gem provides features for manipulate with 1C:Enterprise applications as easy
as possible.

Main thing of this gem `class AssMaintainer::InfoBase` provides
some methods for manipulate with information base;

## Realase note

### v.0.1.0

- Not support infobases deployed on 1C:Enterprise server
- Not support configuration extensions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ass_maintainer-info_base'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ass_maintainer-info_base

## Usage

Small example:

```ruby
reqiure 'ass_maintainer/info_base'

# As infobase admin you should make backups of infobase

# Describe connection string
connection_string = 'File="infobase_path";'

# Get InfoBase instanse
ib = AssMaintainer::InfoBase.new('infobase_name', connection_string, read_only)

# Dump data
ib.dump(dump_path)


# As 1C application developer you should make dump of infobase configuration

# Dump configuration
ibi.cfg.dump(cf_dump_path)

# ... etc

```

For more examples see [examples](./test/examples_test.rb)

## Test

For runns tests reqiure install 1C:Enterprise platform version defined in
constant `AssMaintainer::InfoBaseTest::PLATFORM_REQUIRE` in
[test_helper.rb](./test/test_helper.rb)

    $export SIMPLECOV=YES && rake test

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec ass_maintainer-info_base` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ass_maintainer-info_base.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

