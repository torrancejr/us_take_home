# frozen_string_literal: true

require "test_helper"

class AgencyTest < ActiveSupport::TestCase
  test "should require name" do
    agency = Agency.new(slug: "test")
    assert_not agency.valid?
    assert_includes agency.errors[:name], "can't be blank"
  end

  test "should require slug" do
    agency = Agency.new(name: "Test")
    assert_not agency.valid?
    assert_includes agency.errors[:slug], "can't be blank"
  end

  test "should require unique slug" do
    Agency.create!(name: "First", slug: "test-slug")
    agency = Agency.new(name: "Second", slug: "test-slug")
    assert_not agency.valid?
  end

  test "should create valid agency" do
    agency = Agency.new(name: "Test Agency", slug: "test-agency")
    assert agency.valid?
  end
end

