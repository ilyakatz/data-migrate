<% options.classes.each do |class_name| %>class <%= class_name %> < <%= class_name.constantize.superclass.name %>
  set_table_name '<%= class_name.constantize.table_name %>'
<% class_name.constantize.reflect_on_all_associations.each do |assoc| %>  <%= assoc.macro %> :<%= assoc.name %>, <%= assoc.options.to_s %>
<% end %>end

<% end %>