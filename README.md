# Sequel::ForceHooks

Sequel extension that allows to trigger `after_commit` and `after_rollback` hooks on savepoints.

This is particularly useful for testing callbacks side-effects on transaction tests (and probably in no other circumstances).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sequel-force-hooks'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install sequel-force-hooks

## Requirements

`sequel-force-hooks` requires `sequel` `5.28.0` or newer, if you need to use an older version try this gem instead: [sequel-savepoint-hooks](https://github.com/chanks/sequel-savepoint-hooks).

## Usage

Let's say you have transactional tests setup and want to make sure you callbacks' side-effects callbacks run properly.
This could force you to treat it as a special case, moving all the transactional logic inside the test, with this gem you can forget about all the extra complications and simply write your test like any other, focusing on what you actually care.

In order to benefit from this gem you need to setup you test suite for [transactional testing](https://sequel.jeremyevans.net/rdoc/files/doc/testing_rdoc.html#label-rspec+-3E-3D+2.8) as usual and tell the `sequel` DB to run all the registered callbacks on the savepoint you want instead of the outermost one. Let's see an example using `RSpec`.

Say we have a `FooService` class that puts a job for background execution.

```ruby
# lib/foo_service.rb

class FooService
  def call
    DB.transaction do
      # Do some work here...

      # Only run if commit was successful
      after_commit do
        FooWorker.perform_async
      end
    end
  end
end
```

We want to test that the `FooWorker` was enqueued only if the commit was successful.

We need to setup our transactional test suite to run the callbacks after the outermost `transaction` call at `FooService`, like it would happen in production.
To that end, we need to setup a transaction around our test examples to discard any DB changes (using `rollback: :always`), set `auto_savepoint: true` (to create a savepoint inside the first transaction inside our code) and pass the `force_hooks: :nested` option, this will force the callbacks to run at the savepoint level.

```ruby
# spec/spec_helper.rb

# Setup your DB connection as usual
DB = Sequel.connect('mysql2://user:@localhost:3306/my_test_db')

# Load the :force_hooks extension only for the test suite
DB.extension(:force_hooks)

RSpec.configure do |config|
  # Config RSpec as usual...

  # Setup an around hook for every test
  config.around(:each) do |example|
    # Tell sequel to rollback your tests after every example has run, setup a savepoint on the first
    # innermost transaction and ran all the callbacks there by passing 'force_hooks: :nested'
    DB.transaction(rollback: :always, auto_savepoint: true, force_hooks: :nested) do
      example.run
    end
  end
end
```

And finally we test that a `FooWorker` job was enqueued properly:

```ruby
# spec/foo_spec.rb

require 'spec/spec_helper'

RSpec.describe FooService do
  context 'when is successful' do
    subject(:foo_service) { FooService.new }

    before do
      foo_service.call
    end

    it 'must enqueue a job' do
      expect(FooWroker.jobs).to eq(1)
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pabloh/sequel-force-hooks.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


## Thanks

- Jeremy Evans (@jeremyevans), for creating the awesome [sequel](https://github.com/jeremyevans/sequel) gem
- Chris Hanks (@chanks), for creating the [sequel-savepoint-hooks](https://github.com/chanks/sequel-savepoint-hooks) extension, that originally inspired this gem
