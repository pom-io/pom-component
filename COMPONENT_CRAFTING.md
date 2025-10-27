# Component Crafting Guide

This guide demonstrates how to create components using the Pom component framework, from basic single-element components to complex multi-part compositions.

## Table of Contents

- [Basic Components](#basic-components)
- [Complex Components with Multiple Elements](#complex-components-with-multiple-elements)
- [Composite Components with Slots](#composite-components-with-slots)
- [Best Practices](#best-practices)

---

## Basic Components

Basic components render a single HTML element with configurable options and styles.

### Component Class

```ruby
# app/components/my/button_component.rb
class My::ButtonComponent < Pom::Component
  # Define component options with enums and defaults
  option :color, enums: [:red, :green, :blue], default: :red
  option :variant, enums: [:solid, :outline, :ghost], default: :solid
  option :size, enums: [:sm, :md, :lg], default: :md
  option :disabled, default: false
  option :submit, default: false

  # Define styles using Tailwind CSS classes
  # Supports conditional styling based on option values
  define_styles(
    base: "inline-flex items-center justify-center font-medium rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2",
    variant: {
      solid: "border-transparent shadow-sm",
      outline: "border-2 bg-transparent",
      ghost: "border-transparent bg-transparent hover:bg-opacity-10"
    },
    color: {
      red: "text-white bg-red-600 hover:bg-red-700 focus:ring-red-500",
      blue: "text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-500",
      green: "text-white bg-green-600 hover:bg-green-700 focus:ring-green-500"
    },
    size: {
      sm: "px-3 py-1.5 text-sm",
      md: "px-4 py-2 text-base",
      lg: "px-6 py-3 text-lg"
    },
    disabled: {
      true: "opacity-50 cursor-not-allowed pointer-events-none",
      false: "cursor-pointer"
    }
  )

  # Define default HTML attributes and merge computed styles
  def default_options
    {
      class: styles_for(variant: variant, color: color, size: size, disabled: disabled),
      type: submit ? "submit" : "button",
      disabled: disabled,
      aria: { label: "Button" }
    }
  end

  # Option 1: Inline rendering (preferred for simple components)
  def call
    tag.button(content, **merge_options(default_options, extra_options))
  end
end
```

### Alternative: Template File

For components where you prefer separating markup:

```erb
<!-- app/components/my/button_component.html.erb -->
<%= tag.button(**merge_options(default_options, extra_options)) do %>
  <%= content %>
<% end %>
```

**Note:** When using a template file, remove the `call` method from the component class.

### Usage in Views

```erb
<%= my_button(variant: :outline, color: :blue, size: :lg) do %>
  Click Me
<% end %>

<!-- With custom HTML attributes -->
<%= my_button(variant: :solid, color: :red, submit: true, class: "custom-class", data: { action: "click->controller#action" }) do %>
  Submit Form
<% end %>

<!-- Disabled state -->
<%= my_button(disabled: true) do %>
  Disabled Button
<% end %>
```

---

## Complex Components with Multiple Elements

Components with multiple nested elements should define separate style sets for each element and use template files for clarity.

### Component Class

```ruby
# app/components/my/card_component.rb
class My::CardComponent < Pom::Component
  option :variant, enums: [:default, :bordered, :elevated], default: :default
  option :padding, enums: [:sm, :md, :lg], default: :md
  option :rounded, default: true

  # Extra options for the root wrapper element
  option :root_options, default: {}

  # Define styles for the root element
  define_styles(
    :root,
    base: "w-full bg-white overflow-hidden",
    variant: {
      default: "border border-gray-200",
      bordered: "border-2 border-gray-300",
      elevated: "shadow-lg"
    },
    rounded: {
      true: "rounded-lg",
      false: ""
    }
  )

  # Define styles for the primary content element
  define_styles(
    base: "w-full",
    padding: {
      sm: "p-3",
      md: "p-4",
      lg: "p-6"
    }
  )

  def default_root_options
    {
      class: styles_for(:root, variant: variant, rounded: rounded)
    }
  end

  def default_options
    {
      class: styles_for(padding: padding)
    }
  end
end
```

### Template File

```erb
<!-- app/components/my/card_component.html.erb -->
<%= tag.div(**merge_options(default_root_options, root_options)) do %>
  <%= tag.div(**merge_options(default_options, extra_options)) do %>
    <%= content %>
  <% end %>
<% end %>
```

### Usage in Views

```erb
<%= my_card(variant: :elevated, padding: :lg) do %>
  <h2>Card Title</h2>
  <p>Card content goes here</p>
<% end %>

<!-- Customize root and content separately -->
<%= my_card(
  variant: :bordered,
  root_options: { class: "max-w-md mx-auto", data: { controller: "card" } },
  class: "text-center"
) do %>
  Centered card content
<% end %>
```

---

## Composite Components with Slots

For components with distinct, reusable sections, use ViewComponent's slot system to create clean, flexible compositions.

### Parent Component

```ruby
# app/components/my/dialog_component.rb
class My::DialogComponent < Pom::Component
  option :open, default: false
  option :size, enums: [:sm, :md, :lg], default: :md

  # Define slots for sub-components
  renders_one :header, My::Dialog::HeaderComponent
  renders_one :body, My::Dialog::BodyComponent
  renders_one :footer, My::Dialog::FooterComponent

  define_styles(
    base: "fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50",
    open: {
      true: "block",
      false: "hidden"
    }
  )

  define_styles(
    :dialog,
    base: "bg-white rounded-lg shadow-xl",
    size: {
      sm: "max-w-sm",
      md: "max-w-md",
      lg: "max-w-lg"
    }
  )

  def default_options
    {
      class: styles_for(open: open)
    }
  end

  def default_dialog_options
    {
      class: styles_for(:dialog, size: size),
      role: "dialog",
      aria: { modal: true }
    }
  end
end
```

### Parent Template

```erb
<!-- app/components/my/dialog_component.html.erb -->
<%= tag.div(**merge_options(default_options, extra_options)) do %>
  <%= tag.div(**default_dialog_options) do %>
    <%= header %>
    <%= body %>
    <%= footer %>
  <% end %>
<% end %>
```

### Sub-Components

```ruby
# app/components/my/dialog/header_component.rb
class My::Dialog::HeaderComponent < Pom::Component
  define_styles(
    base: "px-6 py-4 border-b border-gray-200"
  )

  def default_options
    {
      class: styles_for
    }
  end
end

# app/components/my/dialog/body_component.rb
class My::Dialog::BodyComponent < Pom::Component
  define_styles(
    base: "px-6 py-4"
  )

  def default_options
    {
      class: styles_for
    }
  end
end

# app/components/my/dialog/footer_component.rb
class My::Dialog::FooterComponent < Pom::Component
  define_styles(
    base: "px-6 py-4 border-t border-gray-200 flex justify-end gap-2"
  )

  def default_options
    {
      class: styles_for
    }
  end
end
```

### Sub-Component Templates

```erb
<!-- app/components/my/dialog/header_component.html.erb -->
<%= tag.div(**merge_options(default_options, extra_options)) do %>
  <%= content %>
<% end %>

<!-- app/components/my/dialog/body_component.html.erb -->
<%= tag.div(**merge_options(default_options, extra_options)) do %>
  <%= content %>
<% end %>

<!-- app/components/my/dialog/footer_component.html.erb -->
<%= tag.div(**merge_options(default_options, extra_options)) do %>
  <%= content %>
<% end %>
```

### Usage in Views

```erb
<%= my_dialog(open: true, size: :lg) do |c| %>
  <% c.with_header do %>
    <h3 class="text-lg font-semibold">Confirm Action</h3>
  <% end %>

  <% c.with_body do %>
    <p>Are you sure you want to proceed with this action?</p>
  <% end %>

  <% c.with_footer do %>
    <%= my_button(variant: :ghost) { "Cancel" } %>
    <%= my_button(variant: :solid, color: :red) { "Confirm" } %>
  <% end %>
<% end %>
```

---

## Best Practices

### Component Structure

1. **Keep nesting shallow**: Limit component nesting to 2-3 levels maximum
2. **Use slots for sub-components**: Instead of passing options for each sub-element, use `renders_one` or `renders_many` slots
3. **Separate concerns**: Use template files for complex markup; keep component classes focused on logic and configuration

### Options Pattern

```ruby
# DON'T - Too many granular options for sub-elements
option :header_class, default: ""
option :header_padding, default: :md
option :body_class, default: ""
option :body_padding, default: :md
option :footer_class, default: ""
option :footer_align, default: :left

# DO - Use slots and let sub-components handle their own options
renders_one :header, My::Dialog::HeaderComponent
renders_one :body, My::Dialog::BodyComponent
renders_one :footer, My::Dialog::FooterComponent
```

### Style Organization

1. **Always define a base class**: Common styles shared across all variants
2. **Use consistent naming**: Match style keys to option names for clarity
3. **Leverage Tailwind**: Use utility classes for rapid development
4. **Keep specificity low**: Avoid overly specific selectors; make components easily customizable

### Naming Conventions

1. **Component files**: `app/components/namespace/component_name_component.rb`
2. **Template files**: `app/components/namespace/component_name_component.html.erb`
3. **Sub-components**: `app/components/namespace/parent_name/sub_name_component.rb`
4. **Helper methods**: `namespace_component_name` (auto-generated), see configuration

### Accessibility

Always include appropriate ARIA attributes and semantic HTML:

```ruby
def default_options
  {
    class: styles_for(...),
    role: "button",
    aria: { label: "Descriptive label" },
    tabindex: disabled ? -1 : 0
  }
end
```

### Customization Strategy

Allow users to override styles and attributes at multiple levels:

```erb
<!-- Override component-level defaults -->
<%= my_card(variant: :elevated, class: "custom-class") do %>
  Content
<% end %>

<!-- Override root wrapper -->
<%= my_card(root_options: { class: "container mx-auto", data: { controller: "modal" } }) do %>
  Content
<% end %>

<!-- Override slot content -->
<%= my_dialog do |c| %>
  <% c.with_header(class: "bg-gray-100") do %>
    Custom Header
  <% end %>
<% end %>
```

### Testing Recommendations

Test component rendering, option handling, and style application:

```ruby
# test/components/my/button_component_test.rb
class My::ButtonComponentTest < ViewComponent::TestCase
  def test_renders_with_defaults
    render_inline(My::ButtonComponent.new) { "Click me" }
    assert_selector "button[type='button']", text: "Click me"
  end

  def test_applies_variant_styles
    render_inline(My::ButtonComponent.new(variant: :outline))
    assert_selector "button.border-2"
  end

  def test_submit_type
    render_inline(My::ButtonComponent.new(submit: true))
    assert_selector "button[type='submit']"
  end
end
```
