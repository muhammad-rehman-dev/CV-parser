ActiveAdmin.register Language do
  menu parent: "Configuration"
  permit_params :name, :position, :active
end
