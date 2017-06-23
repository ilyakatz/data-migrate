require 'spec_helper'

describe 'db:migrate:with_data' do
  include_context "rake"
  it "runs with staging parameters" do
    subject.invoke
  end
end
