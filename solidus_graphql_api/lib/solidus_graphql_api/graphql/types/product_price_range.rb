module Spree::GraphQL::Types::ProductPriceRange


  # Field: maxVariantPrice: The highest variant's price.
  # Args: 
  # Returns: Types::MoneyV2!
  def max_variant_price()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: minVariantPrice: The lowest variant's price.
  # Args: 
  # Returns: Types::MoneyV2!
  def min_variant_price()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

end
