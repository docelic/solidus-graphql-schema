require 'spec_helper'

describe 'Payloads' do
  describe 'CheckoutDiscountCodeApply' do
    #let!(:checkout_discount_code_apply_payload) {create(:checkout_discount_code_apply_payload)}

    # Field: checkout: The updated checkout object.
    # Args: 
    # Returns: Types::Checkout!
    #it 'checkout' do
    #  query = <<-GRAPHQL
    #    { checkout_discount_code_apply_payload { checkout() }}
    #  GRAPHQL
    #  response = ::Spree::GraphQL::Schema::Schema.execute(query)
    #  result = response.dig('data', 'checkout_discount_code_apply_payload')
    #  expect(result['checkout']).to eq checkout_discount_code_apply_payload.checkout
    #end

    # Field: userErrors: List of errors that occurred executing the mutation.
    # Args: 
    # Returns: [Types::UserError!]!
    #it 'user_errors' do
    #  query = <<-GRAPHQL
    #    { checkout_discount_code_apply_payload { userErrors() }}
    #  GRAPHQL
    #  response = ::Spree::GraphQL::Schema::Schema.execute(query)
    #  result = response.dig('data', 'checkout_discount_code_apply_payload')
    #  expect(result['userErrors']).to eq checkout_discount_code_apply_payload.user_errors
    #end

  end
end
