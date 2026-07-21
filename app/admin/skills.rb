ActiveAdmin.register Skill do
  menu parent: "Configuration"
  permit_params :name, :job_function_id, :position, :active

  index do
    selectable_column
    column :name
    column :job_function
    column :position
    column :active
    actions
  end

  filter :job_function
  filter :name

  form do |f|
    f.inputs do
      f.input :name
      f.input :job_function
      f.input :position
      f.input :active
    end
    f.actions
  end
end
