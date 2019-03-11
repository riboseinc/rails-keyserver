# Truncate key to 32 bytes as required by encryptor gem
Rails::Keyserver::Engine.config.encryption_key = ("hi" * 32)[0...32]
