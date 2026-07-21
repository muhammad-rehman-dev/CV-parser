class MakeEducationStudyNotNull < ActiveRecord::Migration[7.2]
  def up
    # Study is always required by the model, so any legacy blank rows are invalid.
    execute("DELETE FROM educations WHERE study IS NULL OR study = ''")
    change_column_null :educations, :study, false
  end

  def down
    change_column_null :educations, :study, true
  end
end
