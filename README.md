# eCFR Analyzer

A simple Rails app that pulls federal regulation data from the eCFR API and helps you analyze it.

## What it does

- Downloads regulation data for all federal agencies
- Tracks word counts, section counts, and changes over time
- Shows which industries each agency regulates most (healthcare, finance, energy, etc.)

## Requirements

- Ruby 3.2+
- Rails 7.2
- SQLite 3

## Setup in terminal
```bash
bundle install
rails db:create db:migrate
```

## Get some data
```bash
bin/rails ecfr:ingest
```

Want to track changes over time? Pull data from a year ago too:

```bash
bin/rails ecfr:ingest DATE=2024-12-17
bin/rails ecfr:ingest DATE=2025-12-15
```

Now you'll see growth rates and changes between those dates.

## Run the app

```bash
bin/dev
```

Open http://localhost:3000

## Run tests

bin/rails test


## How it works

The app uses the [eCFR API](https://www.ecfr.gov/developers/documentation/api/v1) to fetch regulation structure data. It stores snapshots in SQLite and calculates:

- Word Count - estimated from byte size
- Sections - number of regulatory sections
- Growth Rate - % change between snapshots
- Industry Targeting - which sectors the regulations mention most (finance, healthcare, etc.)
- Checksum - SHA-256 hash to detect changes

The services folder contains the eCFR ingestion logic. The ecfr_ingestor.rb file is responsible for fetching data from the eCFR API, computing metrics, and storing snapshot results in the database.

The controllers folder handles both the web interface and the JSON API. The dashboard controller powers the browser-based UI used to review agency data, while the API controller exposes read-only endpoints for accessing the stored metrics programmatically.

The models folder contains the data structures. The agency model represents a federal agency, and the agency snapshot model stores per-agency metrics over time, including word counts, checksums, and other values.

The views/dashboard folder contains the Tailwind-styled templates used to display the dashboard and agency detail pages.