module Spree::GraphQL::Types::ProductVariant
  include ::Spree::GraphQL::Interfaces::Node

  # Field: availableForSale: Indicates if the product variant is available for sale.
  # Returns: ::GraphQL::Types::Boolean, null: false
  def available_for_sale()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: compareAtPrice: The compare at price of the variant. This can be used to mark a variant as on sale, when `compareAtPrice` is higher than `price`.
  # Returns: Types::Money, null: true
  def compare_at_price()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: id: Globally unique identifier.
  # Returns: ::GraphQL::Types::ID, null: false
  def id()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: image: Image associated with the product variant. This field falls back to the product image if no image is available.
  # Defaults: scale = 1
  # Returns: Types::Image, null: true
  def image(max_width:, max_height:, crop:, scale:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: price: The product variant’s price.
  # Returns: Types::Money, null: false
  def price()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: product: The product object that the product variant belongs to.
  # Returns: Types::Product, null: false
  def product()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: selectedOptions: List of product options applied to the variant.
  # Returns: [Types::SelectedOption], null: false
  def selected_options()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: sku: The SKU (stock keeping unit) associated with the variant.
  # Returns: ::GraphQL::Types::String, null: true
  def sku()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: title: The product variant’s title.
  # Returns: ::GraphQL::Types::String, null: false
  def title()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: weight: The weight of the product variant in the unit system specified with `weight_unit`.
  # Returns: ::GraphQL::Types::Float, null: true
  def weight()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: weightUnit: Unit of measurement for weight.
  # Returns: Types::WeightUnit, null: false
  def weight_unit()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

end

