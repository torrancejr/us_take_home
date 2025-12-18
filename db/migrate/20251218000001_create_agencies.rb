# frozen_string_literal: true

class CreateAgencies < ActiveRecord::Migration[7.2]
  def change
    create_table :agencies do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :agencies, :slug, unique: true
  end
end

