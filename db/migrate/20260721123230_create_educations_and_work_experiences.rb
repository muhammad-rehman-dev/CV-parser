class CreateEducationsAndWorkExperiences < ActiveRecord::Migration[7.2]
  def change
    create_table :educations do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.string :institution
      t.string :study
      t.string :city_and_country
      t.integer :level
      t.date :start_date
      t.date :end_date

      t.timestamps
    end

    create_table :work_experiences do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.string :job_title
      t.string :company_name
      t.text :responsibilities
      t.date :start_date
      t.date :end_date
      t.boolean :current_job, null: false, default: false

      t.timestamps
    end
  end
end
