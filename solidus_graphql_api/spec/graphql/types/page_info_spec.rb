# frozen_string_literal: true
require 'spec_helper'

module Spree::GraphQL
  describe 'Types::PageInfo' do
    #let!(:page_info) { create(:page_info) }
    #let!(:ctx) { { current_store: ::Spree::Store.where(default: true).first } }
    #let!(:variables) { }

    # hasNextPage: Indicates if there are more pages to fetch.
    # @return [Types::Boolean!]
    describe 'hasNextPage' do
      let!(:query) { '{ page_info { hasNextPage } }' }
      let!(:result) { { data: { page_info: { hasNextPage: '' }}} }
      #it 'succeeds' do
      #  execute
      #  expect(response_hash).to eq(result_hash)
      #end
    end

    # hasPreviousPage: Indicates if there are any pages prior to the current page.
    # @return [Types::Boolean!]
    describe 'hasPreviousPage' do
      let!(:query) { '{ page_info { hasPreviousPage } }' }
      let!(:result) { { data: { page_info: { hasPreviousPage: '' }}} }
      #it 'succeeds' do
      #  execute
      #  expect(response_hash).to eq(result_hash)
      #end
    end

  end
end
