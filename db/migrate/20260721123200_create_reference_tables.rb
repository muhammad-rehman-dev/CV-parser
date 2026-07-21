class CreateReferenceTables < ActiveRecord::Migration[7.2]
  def change
    create_table :job_functions do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.boolean :requires_big_registration, null: false, default: false
      t.boolean :revenue_based, null: false, default: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :job_functions, :slug, unique: true

    create_table :regions do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :regions, :name, unique: true

    create_table :employment_types do |t|
      t.string :name, null: false
      t.string :slug, null: false
      # category drives compensation logic: "employed" -> salary,
      # "self_employed" -> percentage.
      t.string :category, null: false, default: "employed"
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :employment_types, :slug, unique: true

    create_table :languages do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :languages, :name, unique: true

    create_table :skills do |t|
      t.references :job_function, null: true, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :skills, [:job_function_id, :name], unique: true
  end
end
