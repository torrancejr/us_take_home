# frozen_string_literal: true

namespace :ecfr do
  desc "Ingest eCFR data and store snapshots for all agencies"
  task ingest: :environment do
    date = ENV["DATE"] ? Date.parse(ENV["DATE"]) : Date.current
    puts "Starting eCFR ingestion for #{date}..."

    ingestor = EcfrIngestor.new
    count = ingestor.ingest_all(snapshot_date: date)

    puts "✓ Ingested #{count} agencies for #{date}"
  end

  desc "Ingest a single agency by slug"
  task ingest_agency: :environment do
    slug = ENV["SLUG"]
    raise "SLUG environment variable required" unless slug

    date = ENV["DATE"] ? Date.parse(ENV["DATE"]) : Date.current

    ingestor = EcfrIngestor.new
    agency_hash = { "slug" => slug, "name" => slug.titleize }
    ingestor.ingest_agency(agency_hash, snapshot_date: date)

    puts "✓ Ingested agency: #{slug} for #{date}"
  end
end

