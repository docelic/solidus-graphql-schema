module Spree::GraphQL::Types::Payment
  include ::Spree::GraphQL::Interfaces::Node

  # The amount of the payment.
  # Returns: Types::Money, null: false
  def amount()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # The billing address for the payment.
  # Returns: Types::MailingAddress, null: true
  def billing_address()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # The checkout to which the payment belongs.
  # Returns: Types::Checkout, null: false
  def checkout()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # The credit card used for the payment in the case of direct payments.
  # Returns: Types::CreditCard, null: true
  def credit_card()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # An message describing a processing error during asynchronous processing.
  # Returns: ::GraphQL::Types::String, null: true
  def error_message()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Globally unique identifier.
  # Returns: ::GraphQL::Types::ID, null: false
  def id()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # A client-side generated token to identify a payment and perform idempotent operations.
  # Returns: ::GraphQL::Types::String, null: true
  def idempotency_key()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Whether or not the payment is still processing asynchronously.
  # Returns: ::GraphQL::Types::Boolean, null: false
  def ready()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # A flag to indicate if the payment is to be done in test mode for gateways that support it.
  # Returns: ::GraphQL::Types::Boolean, null: false
  def test()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # The actual transaction recorded by Store after having processed the payment with the gateway.
  # Returns: Types::Transaction, null: true
  def transaction()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # A payment applied to a checkout.
  # Returns: Types::Transaction, null: true
  def payment()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

end

