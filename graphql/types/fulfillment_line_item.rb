module Spree::GraphQL::Types::FulfillmentLineItem


  # Field: lineItem: The associated order's line item.
  # Returns: Types::OrderLineItem, null: false
  def line_item()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: quantity: The amount fulfilled in this fulfillment.
  # Returns: ::GraphQL::Types::Int, null: false
  def quantity()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

end

