# frozen_string_literal: true
require 'spec_helper'

module Spree::GraphQL
  describe 'Types::ShopPolicy' do
    #let!(:shop_policy) { create(:shop_policy) }
    #let!(:ctx) { { current_store: ::Spree::Store.where(default: true).first } }
    #let!(:variables) { }

    # body: Policy text, maximum size of 64kb.
    # @return [Types::String!]
    describe 'body' do
      let!(:query) { '{ shop_policy { body } }' }
      let!(:result) { { data: { shop_policy: { body: '' }}} }
      #it 'succeeds' do
      #  execute
      #  expect(response_hash).to eq(result_hash)
      #end
    end

    # id: Globally unique identifier.
    # @return [Types::ID!]
    describe 'id' do
      let!(:query) { '{ shop_policy { id } }' }
      let!(:result) { { data: { shop_policy: { id: '' }}} }
      #it 'succeeds' do
      #  execute
      #  expect(response_hash).to eq(result_hash)
      #end
    end

    # title: Policy’s title.
    # @return [Types::String!]
    describe 'title' do
      let!(:query) { '{ shop_policy { title } }' }
      let!(:result) { { data: { shop_policy: { title: '' }}} }
      #it 'succeeds' do
      #  execute
      #  expect(response_hash).to eq(result_hash)
      #end
    end

    # url: Public URL to the policy.
    # @return [Types::URL!]
    describe 'url' do
      let!(:query) { '{ shop_policy { url } }' }
      let!(:result) { { data: { shop_policy: { url: '' }}} }
      #it 'succeeds' do
      #  execute
      #  expect(response_hash).to eq(result_hash)
      #end
    end

  end
end
