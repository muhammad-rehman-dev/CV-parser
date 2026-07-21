ActiveAdmin.register EmploymentType do
  menu parent: "Configuration"
  permit_params :name, :slug, :category, :position, :active

  form do |f|
    f.inputs do
      f.input :name
      f.input :slug
      f.input :category, as: :select, collection: EmploymentType::CATEGORIES
      f.input :position
      f.input :active
    end
    f.actions
  end
end
