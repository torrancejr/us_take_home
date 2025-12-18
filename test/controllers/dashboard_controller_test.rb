# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "Test Agency", slug: "test-agency")
    @snapshot = AgencySnapshot.create!(
      agency: @agency,
      snapshot_date: Date.current,
      word_count: 10000,
      section_count: 50,
      checksum_sha256: "abc123",
      metrics_json: { industry_scores: {} }.to_json
    )
  end

  test "should get index" do
    get root_path
    assert_response :success
    assert_select "h1", /Federal Regulations Dashboard/
  end

  test "should get show" do
    get dashboard_agency_path(@agency)
    assert_response :success
    assert_select "h1", @agency.name
  end

  test "index displays agency data" do
    get dashboard_path
    assert_response :success
    assert_match @agency.name, response.body
  end
end

