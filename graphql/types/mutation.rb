module Spree::GraphQL::Types::Mutation


  # Field: checkoutAttributesUpdateV2: Updates the attributes of a checkout.
  # Returns: Payloads::CheckoutAttributesUpdateV2, null: true
  def checkout_attributes_update_v2(checkout_id:, input:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutCompleteFree
  # Returns: Payloads::CheckoutCompleteFree, null: true
  def checkout_complete_free(checkout_id:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutCompleteWithCreditCardV2: Completes a checkout using a credit card token from Store's Vault.
  # Returns: Payloads::CheckoutCompleteWithCreditCardV2, null: true
  def checkout_complete_with_credit_card_v2(checkout_id:, payment:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutCompleteWithTokenizedPaymentV2: Completes a checkout with a tokenized payment.
  # Returns: Payloads::CheckoutCompleteWithTokenizedPaymentV2, null: true
  def checkout_complete_with_tokenized_payment_v2(checkout_id:, payment:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutCreate: Creates a new checkout.
  # Returns: Payloads::CheckoutCreate, null: true
  def checkout_create(input:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutCustomerAssociateV2: Associates a customer to the checkout.
  # Returns: Payloads::CheckoutCustomerAssociateV2, null: true
  def checkout_customer_associate_v2(checkout_id:, customer_access_token:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutCustomerDisassociate: Disassociates the current checkout customer from the checkout.
  # Returns: Payloads::CheckoutCustomerDisassociate, null: true
  def checkout_customer_disassociate(checkout_id:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutDiscountCodeApply: Applies a discount to an existing checkout using a discount code.
  # Returns: Payloads::CheckoutDiscountCodeApply, null: true
  def checkout_discount_code_apply(discount_code:, checkout_id:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutDiscountCodeRemove: Removes the applied discount from an existing checkout.
  # Returns: Payloads::CheckoutDiscountCodeRemove, null: true
  def checkout_discount_code_remove(checkout_id:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutEmailUpdate: Updates the email on an existing checkout.
  # Returns: Payloads::CheckoutEmailUpdate, null: true
  def checkout_email_update(checkout_id:, email:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutGiftCardRemove: Removes an applied gift card from the checkout.
  # Returns: Payloads::CheckoutGiftCardRemove, null: true
  def checkout_gift_card_remove(applied_gift_card_id:, checkout_id:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutGiftCardsAppend: Appends gift cards to an existing checkout.
  # Returns: Payloads::CheckoutGiftCardsAppend, null: true
  def checkout_gift_cards_append(gift_card_codes:, checkout_id:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutLineItemsAdd: Adds a list of line items to a checkout.
  # Returns: Payloads::CheckoutLineItemsAdd, null: true
  def checkout_line_items_add(line_items:, checkout_id:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutLineItemsRemove: Removes line items from an existing checkout
  # Returns: Payloads::CheckoutLineItemsRemove, null: true
  def checkout_line_items_remove(checkout_id:, line_item_ids:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutLineItemsUpdate: Updates line items on a checkout.
  # Returns: Payloads::CheckoutLineItemsUpdate, null: true
  def checkout_line_items_update(checkout_id:, line_items:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutShippingAddressUpdate: Updates the shipping address of an existing checkout.
  # Returns: Payloads::CheckoutShippingAddressUpdate, null: true
  def checkout_shipping_address_update(shipping_address:, checkout_id:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutShippingLineUpdate: Updates the shipping lines on an existing checkout.
  # Returns: Payloads::CheckoutShippingLineUpdate, null: true
  def checkout_shipping_line_update(checkout_id:, shipping_rate_handle:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerAccessTokenCreate: Creates a customer access token. The customer access token is required to modify the customer object in any way. 
  # Returns: Payloads::CustomerAccessTokenCreate, null: true
  def customer_access_token_create(input:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerAccessTokenDelete: Permanently destroys a customer access token.
  # Returns: Payloads::CustomerAccessTokenDelete, null: true
  def customer_access_token_delete(customer_access_token:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerAccessTokenRenew: Renews a customer access token. Access token renewal must happen *before* a token expires. If a token has already expired, a new one should be created instead via `customerAccessTokenCreate`. 
  # Returns: Payloads::CustomerAccessTokenRenew, null: true
  def customer_access_token_renew(customer_access_token:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerActivate: Activates a customer.
  # Returns: Payloads::CustomerActivate, null: true
  def customer_activate(id:, input:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerAddressCreate: Creates a new address for a customer.
  # Returns: Payloads::CustomerAddressCreate, null: true
  def customer_address_create(customer_access_token:, address:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerAddressDelete: Permanently deletes the address of an existing customer.
  # Returns: Payloads::CustomerAddressDelete, null: true
  def customer_address_delete(id:, customer_access_token:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerAddressUpdate: Updates the address of an existing customer.
  # Returns: Payloads::CustomerAddressUpdate, null: true
  def customer_address_update(customer_access_token:, id:, address:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerCreate: Creates a new customer.
  # Returns: Payloads::CustomerCreate, null: true
  def customer_create(input:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerDefaultAddressUpdate: Updates the default address of an existing customer.
  # Returns: Payloads::CustomerDefaultAddressUpdate, null: true
  def customer_default_address_update(customer_access_token:, address_id:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerRecover: Sends a reset password email to the customer, as the first step in the reset password process.
  # Returns: Payloads::CustomerRecover, null: true
  def customer_recover(email:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerReset: Resets a customer’s password with a token received from `CustomerRecover`.
  # Returns: Payloads::CustomerReset, null: true
  def customer_reset(id:, input:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerResetByUrl: Resets a customer’s password with the reset password url received from `CustomerRecover`.
  # Returns: Payloads::CustomerResetByUrl, null: true
  def customer_reset_by_url(reset_url:, password:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: customerUpdate: Updates an existing customer.
  # Returns: Payloads::CustomerUpdate, null: true
  def customer_update(customer_access_token:, customer:)
    raise ::Spree::GraphQL::NotImplementedError.new
  end

end

