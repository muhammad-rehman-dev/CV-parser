ActiveAdmin.register JobFunction do
  menu parent: "Configuration"
  permit_params :name, :slug, :requires_big_registration, :revenue_based, :position, :active

  index do
    selectable_column
    column :name
    column :slug
    column :requires_big_registration
    column :revenue_based
    column :position
    column :active
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :slug
      f.input :requires_big_registration
      f.input :revenue_based
      f.input :position
      f.input :active
    end
    f.actions
  end
end
