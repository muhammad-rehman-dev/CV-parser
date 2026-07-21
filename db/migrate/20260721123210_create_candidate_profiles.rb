class CreateCandidateProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :candidate_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :job_function, null: true, foreign_key: true

      # Personal details
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone_number
      t.string :city
      t.string :country

      # Job preferences
      t.integer :max_travel_time
      t.string :transport_types, array: true, null: false, default: []
      t.integer :search_status
      t.text :reason_for_looking

      # Employment and compensation
      t.integer :desired_gross_salary
      t.integer :desired_percentage
      t.decimal :average_daily_revenue, precision: 10, scale: 2
      t.integer :big_registration_status
      t.string :big_number
      t.integer :years_of_experience

      # Availability
      t.string :available_working_days, array: true, null: false, default: []
      t.date :available_from
      t.string :notice_period

      # Additional information
      t.text :professional_summary
      t.text :motivation
      t.text :internal_notes

      # Per-field extraction metadata driving the review badges.
      t.jsonb :field_metadata, null: false, default: {}

      t.datetime :completed_at

      t.timestamps
    end
  end
end
