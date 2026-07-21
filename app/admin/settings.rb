ActiveAdmin.register Setting do
  menu priority: 90, parent: "Configuration"
  permit_params :key, :value, :value_type, :description
  actions :index, :show, :edit, :update

  index do
    selectable_column
    column :key
    column :value
    column :value_type
    column :description
    actions
  end

  form do |f|
    f.inputs do
      f.input :key, input_html: { readonly: true }
      f.input :value
      f.input :value_type, as: :select, collection: Setting::VALUE_TYPES
      f.input :description
    end
    f.actions
  end
end
