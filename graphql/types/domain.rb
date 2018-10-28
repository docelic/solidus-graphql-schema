module Spree::GraphQL::Types::Domain


  # Field: host: The host name of the domain (eg: `example.com`).
  # Returns: ::GraphQL::Types::String, null: false
  def host()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: sslEnabled: Whether SSL is enabled or not.
  # Returns: ::GraphQL::Types::Boolean, null: false
  def ssl_enabled()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: url: The URL of the domain (eg: `https://example.com`).
  # Returns: Types::URL, null: false
  def url()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

end

