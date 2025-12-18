# frozen_string_literal: true

require "test_helper"

class AgencySnapshotTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Test", slug: "test")
  end

  test "should belong to agency" do
    snapshot = AgencySnapshot.new(snapshot_date: Date.current)
    assert_not snapshot.valid?
  end

  test "should require snapshot_date" do
    snapshot = AgencySnapshot.new(agency: @agency)
    assert_not snapshot.valid?
  end

  test "should parse metrics json" do
    snapshot = AgencySnapshot.create!(
      agency: @agency,
      snapshot_date: Date.current,
      metrics_json: { test: "value" }.to_json
    )
    assert_equal "value", snapshot.parsed_metrics["test"]
  end

  test "should handle nil metrics" do
    snapshot = AgencySnapshot.create!(
      agency: @agency,
      snapshot_date: Date.current,
      metrics_json: nil
    )
    assert_equal({}, snapshot.parsed_metrics)
  end
end

