# frozen_string_literal: true

class CreateAgencySnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :agency_snapshots do |t|
      t.references :agency, null: false, foreign_key: true
      t.date :snapshot_date, null: false
      t.integer :word_count, default: 0
      t.integer :section_count, default: 0
      t.string :checksum_sha256
      t.text :metrics_json

      t.timestamps
    end

    add_index :agency_snapshots, [:agency_id, :snapshot_date], unique: true
  end
end

