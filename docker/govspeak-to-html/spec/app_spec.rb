# frozen_string_literal: true

require 'rspec'

# --- UNIT TESTS ---
describe 'app.rb entrypoint', :unit do
  it 'loads successfully without raising an exception' do
    expect do
      load './app.rb'
    end.not_to raise_error
  end
end
