require 'spec_helper'

describe 'Types' do
  describe 'PageInfo' do
    #let!(:page_info) {create(:page_info)}

    # Field: hasNextPage: Indicates if there are more pages to fetch.
    # Args: 
    # Returns: Types::Boolean!
    #it 'has_next_page' do
    #  query = <<-GRAPHQL
    #    { page_info { hasNextPage() }}
    #  GRAPHQL
    #  response = ::Spree::GraphQL::Schema::Schema.execute(query)
    #  result = response.dig('data', 'page_info')
    #  expect(result['hasNextPage']).to eq page_info.has_next_page
    #end

    # Field: hasPreviousPage: Indicates if there are any pages prior to the current page.
    # Args: 
    # Returns: Types::Boolean!
    #it 'has_previous_page' do
    #  query = <<-GRAPHQL
    #    { page_info { hasPreviousPage() }}
    #  GRAPHQL
    #  response = ::Spree::GraphQL::Schema::Schema.execute(query)
    #  result = response.dig('data', 'page_info')
    #  expect(result['hasPreviousPage']).to eq page_info.has_previous_page
    #end

  end
end
