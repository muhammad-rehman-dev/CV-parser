ActiveAdmin.register Region do
  menu parent: "Configuration"
  permit_params :name, :position, :active
end
