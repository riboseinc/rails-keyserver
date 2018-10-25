RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # URL:
  # http://stackoverflow.com/questions/21323239/rspec-factorygirl-clean-database-state
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
    # FactoryBot.find_definitions
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
