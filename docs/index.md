---
layout: default
title: Home
---

# Pom Component

A UI component toolkit for Rails with Tailwind CSS integration. Pom provides a powerful base class for building reusable ViewComponents with advanced features including option management, style composition, and Stimulus.js integration.

## Features

- 🎨 **Styleable DSL** - Compose Tailwind CSS classes with automatic conflict resolution
- ⚙️ **Option DSL** - Define component options with enums, defaults, and validation
- 🎯 **Type Safety** - Enum validation and required option enforcement
- 🔄 **Inheritance** - Full support for component inheritance with style and option merging
- ⚡ **Stimulus Integration** - Built-in helpers for Stimulus.js data attributes
- 🧩 **Flexible** - Capture extra options and merge HTML attributes intelligently

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pom-component'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install pom-component
```

## Requirements

- Ruby >= 3.2.0
- Rails >= 7.1.0
- ViewComponent >= 4.0

## Quick Start

Create your first component by inheriting from `Pom::Component`:

```ruby
# app/components/pom/button_component.rb
module Pom
  class ButtonComponent < Pom::Component
    option :variant, enums: [:primary, :secondary, :danger], default: :primary
    option :size, enums: [:sm, :md, :lg], default: :md
    option :disabled, default: false

    define_styles(
      base: "inline-flex items-center justify-center font-medium rounded transition",
      variant: {
        primary: "bg-blue-600 text-white hover:bg-blue-700",
        secondary: "bg-gray-200 text-gray-800 hover:bg-gray-300",
        danger: "bg-red-600 text-white hover:bg-red-700"
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

    def call
      content_tag :button, content, **html_options
    end

    private

    def html_options
      merge_options(
        { class: styles_for(variant: variant, size: size, disabled: disabled) },
        extra_options
      )
    end
  end
end
```

Use it in your views:

```erb
<%# app/views/pages/index.html.erb %>
<%= render Pom::ButtonComponent.new(variant: :primary, size: :lg) do %>
  Click me!
<% end %>
```

Or using the helper method (component must be in the `Pom::` namespace):

```erb
<%# This looks for Pom::ButtonComponent %>
<%= pom_button(variant: :danger, disabled: true) do %>
  Delete
<% end %>
```

**Note:** The `pom_*` helper methods only work with components defined in the `Pom::` namespace. See [Configuration](#configuration) to learn how to add custom prefixes for other namespaces.

## Component Crafting Guide

For comprehensive examples and best practices on building components from basic to complex compositions, see the [Component Crafting Guide](component-crafting).

## Option DSL

The Option DSL provides a declarative way to define component options with validation, defaults, and type safety.

### Basic Usage

Define options using the `option` class method:

```ruby
class CardComponent < Pom::Component
  option :title
  option :variant, enums: [:default, :bordered, :elevated]
  option :padding, default: :md
end
```

### Option Parameters

#### `enums:`

Restrict option values to a specific set:

```ruby
option :size, enums: [:sm, :md, :lg]
```

This will:

- Validate values on initialization and when using setters
- Accept both symbols and strings (automatically converted to symbols)
- Raise `ArgumentError` for invalid values

```ruby
# Valid
component = MyComponent.new(size: :md)
component = MyComponent.new(size: "lg")

# Invalid - raises ArgumentError
component = MyComponent.new(size: :xl)
```

#### `default:`

Provide a default value when the option is not specified:

```ruby
option :color, default: :blue
option :count, default: 0
option :timestamp, default: -> { Time.current }
```

Defaults can be:

- **Static values**: Strings, symbols, numbers, booleans
- **Procs/Lambdas**: Called at runtime for dynamic defaults

#### `required:`

Mark an option as required:

```ruby
option :user_id, required: true
option :status, required: true, default: :active
```

### Generated Methods

For each option, three methods are automatically generated:

- **Getter Method**: `component.variant`
- **Setter Method**: `component.variant = :secondary` (with validation)
- **Predicate Method**: `component.variant?` (checks if present)

### Extra Options

Any options not explicitly defined are captured in `extra_options`:

```ruby
class MyComponent < Pom::Component
  option :title
end

component = MyComponent.new(title: "Hello", data: { controller: "modal" }, id: "my-modal")

component.title          # => "Hello"
component.extra_options  # => { data: { controller: "modal" }, id: "my-modal" }
```

This is useful for passing through HTML attributes:

```ruby
def call
  content_tag :div, content, **extra_options
end
```

## Styleable

The Styleable module provides a powerful DSL for composing Tailwind CSS classes with automatic conflict resolution using the `tailwind_merge` gem.

### Basic Usage

Define styles using the `define_styles` class method:

```ruby
class AlertComponent < Pom::Component
  option :variant, enums: [:info, :success, :warning, :error], default: :info

  define_styles(
    base: "p-4 rounded-lg border",
    variant: {
      info: "bg-blue-50 border-blue-200 text-blue-800",
      success: "bg-green-50 border-green-200 text-green-800",
      warning: "bg-yellow-50 border-yellow-200 text-yellow-800",
      error: "bg-red-50 border-red-200 text-red-800"
    }
  )

  def call
    content_tag :div, content, class: styles_for(variant: variant)
  end
end
```

### Style Structure

Styles are organized into **keys** that map to option values:

```ruby
define_styles(
  base: "always-applied-classes",
  option_name: {
    option_value_1: "classes-for-value-1",
    option_value_2: "classes-for-value-2"
  }
)
```

### Using styles_for

Generate the class string using `styles_for`:

```ruby
def call
  content_tag :div, content, class: styles_for(variant: variant, size: size)
end
```

The method:

1. Applies base styles
2. Resolves each provided option against style definitions
3. Concatenates all matching classes
4. Uses `tailwind_merge` to resolve conflicts

### Dynamic Styles with Lambdas

Use lambdas for dynamic style computation based on component state:

```ruby
class BadgeComponent < Pom::Component
  option :variant, enums: [:solid, :outline], default: :solid
  option :color, enums: [:blue, :green, :red, :yellow], default: :blue

  define_styles(
    base: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
    variant: {
      solid: ->(color: :blue, **_opts) {
        case color
        when :blue then "bg-blue-100 text-blue-800"
        when :green then "bg-green-100 text-green-800"
        when :red then "bg-red-100 text-red-800"
        when :yellow then "bg-yellow-100 text-yellow-800"
        end
      },
      outline: ->(color: :blue, **_opts) {
        case color
        when :blue then "border border-blue-300 text-blue-700"
        when :green then "border border-green-300 text-green-700"
        when :red then "border border-red-300 text-red-700"
        when :yellow then "border border-yellow-300 text-yellow-700"
        end
      }
    }
  )

  def call
    content_tag :span, content, class: styles_for(variant: variant, color: color)
  end
end
```

**Important:** Always use full Tailwind CSS class names, not string interpolation. Tailwind's JIT compiler needs to see complete class names to generate the CSS.

### Style Groups

Organize styles for different parts of your component:

```ruby
class ModalComponent < Pom::Component
  option :size, enums: [:sm, :md, :lg], default: :md

  define_styles(:overlay, base: "fixed inset-0 bg-black bg-opacity-50")

  define_styles(:dialog,
    base: "bg-white rounded-lg shadow-xl",
    size: {
      sm: "max-w-sm",
      md: "max-w-md",
      lg: "max-w-lg"
    }
  )

  define_styles(:header, base: "px-6 py-4 border-b")
  define_styles(:body, base: "px-6 py-4")
  define_styles(:footer, base: "px-6 py-4 border-t bg-gray-50")

  def call
    content_tag :div, class: styles_for(:overlay) do
      content_tag :div, class: styles_for(:dialog, size: size) do
        concat content_tag(:div, header_content, class: styles_for(:header))
        concat content_tag(:div, body_content, class: styles_for(:body))
        concat content_tag(:div, footer_content, class: styles_for(:footer))
      end
    end
  end
end
```

## Helpers

### OptionHelper

Intelligently merge option hashes:

```ruby
def html_options
  merge_options(
    { class: base_classes, data: { controller: "dropdown" } },
    { class: variant_classes, data: { action: "click->dropdown#toggle" } },
    extra_options
  )
end
```

Special handling for:

- **`:class`**: Merged using `tailwind_merge`
- **`:data`**: Deep merged with concatenation for `controller` and `action`
- Other keys: Last value wins

### ViewHelper

Render Pom components using helper methods:

```ruby
# Instead of:
<%= render Pom::ButtonComponent.new(variant: :primary) { "Click" } %>

# Use:
<%= pom_button(variant: :primary) { "Click" } %>
```

The helper automatically converts `pom_component_name` to `Pom::ComponentNameComponent`.

### StimulusHelper

Generate Stimulus data attributes:

```ruby
class DropdownComponent < Pom::Component
  def stimulus
    "dropdown"
  end

  def button_options
    merge_options(
      stimulus_target(:button),
      stimulus_action({ click: :toggle }),
      { class: "btn" }
    )
  end
end
```

Available helpers:

- `stimulus_target(name, stimulus: nil)` - Generate target attributes
- `stimulus_action(action_map, stimulus: nil)` - Generate action attributes
- `stimulus_value(name, value, stimulus: nil)` - Generate value attributes
- `stimulus_class(name, value, stimulus: nil)` - Generate class attributes
- `stimulus_controller` - Returns the dasherized controller name

## Configuration

You can configure Pom to use custom component prefixes in addition to the default `pom` prefix:

```ruby
# config/initializers/pom.rb
Pom.configure do |config|
  config.component_prefixes << "ui"
  config.component_prefixes << "admin"
end
```

Now you can use helper methods for components in any configured namespace:

```erb
<%# Looks for Ui::CardComponent %>
<%= ui_card(variant: :bordered) do %>
  Card content
<% end %>

<%# Looks for Admin::DashboardComponent %>
<%= admin_dashboard(user: current_user) %>
```

## Testing

Pom components work seamlessly with ViewComponent's testing utilities:

```ruby
# test/components/pom/button_component_test.rb
require "test_helper"

module Pom
  class ButtonComponentTest < ViewComponent::TestCase
    test "renders with default options" do
      render_inline(ButtonComponent.new) { "Click me" }

      assert_selector "button.inline-flex.bg-blue-600"
      assert_text "Click me"
    end

    test "validates enum values" do
      assert_raises(ArgumentError) do
        ButtonComponent.new(variant: :invalid)
      end
    end
  end
end
```

## Complete Example

Here's a comprehensive example combining all features:

```ruby
# app/components/pom/card_component.rb
module Pom
  class CardComponent < Pom::Component
    option :variant, enums: [:default, :bordered, :elevated], default: :default
    option :padding, enums: [:none, :sm, :md, :lg], default: :md
    option :clickable, default: false
    option :href

    define_styles(:container,
      base: "bg-white rounded-lg overflow-hidden",
      variant: {
        default: "border border-gray-200",
        bordered: "border-2 border-gray-900",
        elevated: "shadow-lg"
      },
      clickable: {
        true: "cursor-pointer transition hover:shadow-xl",
        false: ""
      }
    )

    define_styles(:body,
      padding: {
        none: "",
        sm: "p-3",
        md: "p-6",
        lg: "p-8"
      }
    )

    def call
      if href.present?
        link_to href, **container_options do
          content_tag :div, content, class: styles_for(:body, padding: padding)
        end
      else
        content_tag :div, **container_options do
          content_tag :div, content, class: styles_for(:body, padding: padding)
        end
      end
    end

    private

    def container_options
      merge_options(
        {
          class: styles_for(:container, variant: variant, clickable: clickable || href?),
          id: auto_id
        },
        extra_options
      )
    end
  end
end
```

## Resources

- [GitHub Repository](https://github.com/pom-io/pom-component)
- [Component Crafting Guide](component-crafting)
- [RubyGems](https://rubygems.org/gems/pom-component)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

Created by [Hoang Nghiem](https://github.com/hoangnghiem) · Maintained by [Pom](https://github.com/pom-io)
