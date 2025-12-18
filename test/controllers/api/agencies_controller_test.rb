# frozen_string_literal: true

require "test_helper"

class Api::AgenciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "Test Agency", slug: "test-agency")
    @snapshot = AgencySnapshot.create!(
      agency: @agency,
      snapshot_date: Date.current,
      word_count: 5000,
      section_count: 25,
      checksum_sha256: "def456",
      metrics_json: { industry_scores: { "finance" => { "name" => "Finance", "score" => 5.0 } } }.to_json
    )
  end

  test "should get index as json" do
    get api_agencies_path, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert_equal 1, json.size
    assert_equal "Test Agency", json.first["name"]
  end

  test "should get show as json" do
    get api_agency_path(@agency), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "Test Agency", json["name"]
    assert_equal "test-agency", json["slug"]
    assert_equal 1, json["snapshots"].size
  end

  test "index includes word count" do
    get api_agencies_path, as: :json
    json = JSON.parse(response.body)
    assert_equal 5000, json.first["word_count"]
  end
end

