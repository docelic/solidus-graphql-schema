class Spree::GraphQL::Schema::Payloads::CheckoutCompleteWithCreditCardV2 < Spree::GraphQL::Schema::Types::BaseObject
  graphql_name 'CheckoutCompleteWithCreditCardV2Payload'
  description nil

  
  include ::Spree::GraphQL::Payloads::CheckoutCompleteWithCreditCardV2

  field :checkout, ::Spree::GraphQL::Schema::Types::Checkout, null: true do
    description %q{The checkout on which the payment was applied.}
  end
  field :payment, ::Spree::GraphQL::Schema::Types::Payment, null: true do
    description %q{A representation of the attempted payment.}
  end
  field :user_errors, [::Spree::GraphQL::Schema::Types::UserError], null: false do
    description %q{List of errors that occurred executing the mutation.}
  end
end