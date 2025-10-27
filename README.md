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

**Note:** The `pom_*` helper methods only work with components defined in the `Pom::` namespace.

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

```ruby
class TimestampComponent < Pom::Component
  option :created_at, default: -> { Time.current }
  option :format, default: "%Y-%m-%d"
end
```

#### `required:`

Mark an option as required:

```ruby
option :user_id, required: true
option :status, required: true, default: :active
```

Notes:

- Required options without defaults must be provided during initialization
- Required options with defaults don't raise errors (the default satisfies the requirement)
- Missing required options raise `ArgumentError`

```ruby
class UserCardComponent < Pom::Component
  option :name, required: true
  option :email, required: true
  option :role, required: true, default: :member
end

# Valid
UserCardComponent.new(name: "John", email: "john@example.com")

# Invalid - raises ArgumentError: Missing required option: name
UserCardComponent.new(email: "john@example.com")
```

### Generated Methods

For each option, three methods are automatically generated:

#### Getter Method

```ruby
component.variant  # => :primary
```

#### Setter Method (with validation)

```ruby
component.variant = :secondary
component.size = :invalid  # => ArgumentError if enums are defined
```

#### Predicate Method

```ruby
component.variant?  # => true if variant is present
component.title?    # => false if title is nil or empty
```

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

### Class Methods

Query option metadata at the class level:

```ruby
MyComponent.enum_values_for(:variant)      # => [:primary, :secondary, :danger]
MyComponent.default_value_for(:size)       # => :md
MyComponent.required_options               # => [:user_id, :title]
MyComponent.optional_options               # => [:variant, :size, :color]
```

### Instance Methods

Query and manipulate option values:

```ruby
# Get all option values as a hash
component.option_values
# => { variant: :primary, size: :md, disabled: false }

# Check if an option was explicitly set
component.option_set?(:variant)  # => true
component.option_set?(:size)     # => false (using default)

# Reset an option to its default value
component.reset_option(:variant)
component.variant  # => :primary (default)
```

### Inheritance

Options are inherited and can be extended:

```ruby
class BaseButton < Pom::Component
  option :size, enums: [:sm, :md, :lg], default: :md
  option :disabled, default: false
end

class IconButton < BaseButton
  option :icon, required: true
  option :icon_position, enums: [:left, :right], default: :left
end

# IconButton has all options: size, disabled, icon, icon_position
button = IconButton.new(icon: "star", size: :lg)
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

#### Base Styles

Base styles are always applied:

```ruby
define_styles(
  base: "font-sans antialiased"
)
```

Base styles can also be a hash for organization:

```ruby
define_styles(
  base: {
    default: "component rounded-lg",
    hover: "hover:shadow-md",
    focus: "focus:ring-2 focus:ring-blue-500"
  }
)
```

All values in a hash are concatenated and applied.

#### Variant Styles

Map option values to specific classes:

```ruby
define_styles(
  variant: {
    solid: "bg-blue-600 text-white",
    outline: "border-2 border-blue-600 text-blue-600",
    ghost: "text-blue-600 hover:bg-blue-50"
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

**Only the options you pass to `styles_for` will be applied:**

```ruby
# Only applies base and variant styles
styles_for(variant: :primary)

# Applies base, variant, and size styles
styles_for(variant: :primary, size: :lg)
```

### Boolean Style Keys

Handle boolean options elegantly:

```ruby
class ButtonComponent < Pom::Component
  option :disabled, default: false
  option :loading, default: false

  define_styles(
    base: "btn",
    disabled: {
      true: "opacity-50 cursor-not-allowed pointer-events-none",
      false: "cursor-pointer hover:opacity-90"
    },
    loading: {
      true: "animate-pulse",
      false: ""
    }
  )

  def call
    content_tag :button, content, class: styles_for(disabled: disabled, loading: loading)
  end
end
```

### Dynamic Styles with Lambdas

Use lambdas for dynamic style computation:

```ruby
class BadgeComponent < Pom::Component
  option :variant, enums: [:solid, :outline], default: :solid
  option :color, default: "blue"

  define_styles(
    base: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
    variant: {
      solid: ->(color: nil, **_opts) {
        "bg-#{color || 'blue'}-100 text-#{color || 'blue'}-800"
      },
      outline: ->(color: nil, **_opts) {
        "border border-#{color || 'blue'}-300 text-#{color || 'blue'}-700"
      }
    }
  )

  def call
    content_tag :span, content, class: styles_for(variant: variant, color: color)
  end
end

# Usage
<%= render BadgeComponent.new(variant: :solid, color: "green") { "Active" } %>
```

Lambda styles receive all options passed to `styles_for` as keyword arguments.

### Lambda Base Styles

Base styles can also be lambdas:

```ruby
define_styles(
  base: ->(disabled: false, **_opts) {
    classes = ["component rounded-lg transition"]
    classes << "opacity-50" if disabled
    classes.join(" ")
  },
  variant: {
    solid: "bg-blue-600 text-white",
    outline: "border-2 border-blue-600"
  }
)
```

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

Access group styles:

```ruby
styles_for(:group_name, option1: value1, option2: value2)
```

### Tailwind Merge

Pom uses `tailwind_merge` to intelligently resolve conflicting Tailwind classes:

```ruby
# Later classes override earlier ones for the same property
define_styles(
  base: "p-4 bg-blue-500",
  variant: {
    danger: "p-6 bg-red-500"  # p-6 overrides p-4, bg-red-500 overrides bg-blue-500
  }
)

styles_for(variant: :danger)
# => "bg-red-500 p-6"
```

This ensures that:

- Only the most specific class is applied
- No duplicate or conflicting utilities
- Predictable style precedence

### Inheritance

Styles are inherited and merged:

```ruby
class BaseButton < Pom::Component
  option :size, enums: [:sm, :md, :lg], default: :md

  define_styles(
    base: "inline-flex items-center justify-center font-medium rounded",
    size: {
      sm: "px-3 py-1.5 text-sm",
      md: "px-4 py-2 text-base",
      lg: "px-6 py-3 text-lg"
    }
  )
end

class PrimaryButton < BaseButton
  option :variant, enums: [:solid, :outline], default: :solid

  define_styles(
    base: "transition-colors duration-200",  # Merged with parent base
    variant: {
      solid: "bg-blue-600 text-white hover:bg-blue-700",
      outline: "border-2 border-blue-600 text-blue-600 hover:bg-blue-50"
    },
    size: {
      lg: "px-8 py-4 text-xl"  # Overrides parent's lg size
    }
  )
end
```

Child styles:

- Merge with parent styles for the same keys
- Override parent values when there's a conflict
- Add new style keys and variants

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

# Result:
# {
#   class: "merged-classes",  # Uses tailwind_merge
#   data: {
#     controller: "dropdown",
#     action: "click->dropdown#toggle"
#   }
# }
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

**Important:** This only works for components defined in the `Pom::` namespace:

```ruby
# pom_button looks for Pom::ButtonComponent
module Pom
  class ButtonComponent < Pom::Component
    # ...
  end
end
```

If your components are NOT in the `Pom::` namespace, use the regular `render` helper:

```ruby
# For components outside the Pom:: namespace
<%= render ButtonComponent.new(variant: :primary) { "Click" } %>
```

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

  def menu_options
    merge_options(
      stimulus_target(:menu),
      stimulus_class(:open, "block"),
      { class: "dropdown-menu" }
    )
  end
end
```

Available helpers:

#### `stimulus_target(name, stimulus: nil)`

```ruby
stimulus_target(:menu)
# => { "data-dropdown-target" => "menu" }

stimulus_target([:menu, :item])
# => { "data-dropdown-target" => "menu item" }

stimulus_target(:button, stimulus: "modal")
# => { "data-modal-target" => "button" }
```

#### `stimulus_action(action_map, stimulus: nil)`

```ruby
stimulus_action(:toggle)
# => { "data-action" => "dropdown#toggle" }

stimulus_action({ click: :toggle, mouseenter: :show })
# => { "data-action" => "click->dropdown#toggle mouseenter->dropdown#show" }

stimulus_action(:open, stimulus: "modal")
# => { "data-action" => "modal#open" }
```

#### `stimulus_value(name, value, stimulus: nil)`

```ruby
stimulus_value(:open, false)
# => { "data-dropdown-open-value" => false }

stimulus_value(:items, ["a", "b", "c"])
# => { "data-dropdown-items-value" => "[\"a\",\"b\",\"c\"]" }

stimulus_value(:count, 5, stimulus: "counter")
# => { "data-counter-count-value" => 5 }
```

#### `stimulus_class(name, value, stimulus: nil)`

```ruby
stimulus_class(:open, "block")
# => { "data-dropdown-open-class" => "block" }

stimulus_class(:hidden, "hidden", stimulus: "modal")
# => { "data-modal-hidden-class" => "hidden" }
```

#### `stimulus_controller`

Returns the dasherized controller name (requires a `stimulus` method):

```ruby
def stimulus
  "dropdown"
end

stimulus_controller  # => "dropdown"
```

## Component Utilities

### Component Name and ID

Auto-generated component identifiers:

```ruby
class UserCardComponent < Pom::Component
  def call
    content_tag :div, content, id: auto_id, data: { component: component_name }
  end
end

component = UserCardComponent.new
component.component_name  # => "user-card"
component.auto_id         # => "user-card-a3f2"
component.uid             # => "a3f2" (unique 4-char hex)
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

Usage:

```erb
<%= render Pom::CardComponent.new(variant: :elevated, padding: :lg, data: { controller: "card" }) do %>
  <h3 class="text-xl font-bold mb-2">Card Title</h3>
  <p class="text-gray-600">Card content goes here.</p>
<% end %>

<%# Or with the helper %>
<%= pom_card(variant: :bordered, clickable: true, href: "/details") do %>
  <p>Clickable card that links to details page</p>
<% end %>
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

    test "renders disabled button" do
      render_inline(ButtonComponent.new(disabled: true)) { "Disabled" }

      assert_selector "button.opacity-50.cursor-not-allowed"
    end

    test "validates enum values" do
      assert_raises(ArgumentError) do
        ButtonComponent.new(variant: :invalid)
      end
    end

    test "captures extra options" do
      render_inline(ButtonComponent.new(data: { controller: "button" })) { "Click" }

      assert_selector "button[data-controller='button']"
    end
  end
end
```

## Best Practices

### 1. Keep Styles Cohesive

Group related styles together and use meaningful variant names:

```ruby
define_styles(
  base: "btn",
  variant: {
    primary: "bg-blue-600 text-white",
    secondary: "bg-gray-600 text-white",
    danger: "bg-red-600 text-white"
  }
)
```

### 2. Use Required Options for Critical Data

```ruby
option :user, required: true
option :action, required: true
```

### 3. Provide Sensible Defaults

```ruby
option :size, enums: [:sm, :md, :lg], default: :md
option :variant, enums: [:default, :primary], default: :default
```

### 4. Leverage Extra Options

Don't define options for every HTML attribute:

```ruby
def call
  content_tag :div, content, **merge_options(
    { class: styles_for(variant: variant) },
    extra_options  # Captures id, data, aria attributes, etc.
  )
end
```

### 5. Use Style Groups for Complex Components

```ruby
define_styles(:header, base: "...")
define_styles(:body, base: "...")
define_styles(:footer, base: "...")
```

### 6. Validate with Enums

Use enums to catch typos and invalid values early:

```ruby
option :status, enums: [:draft, :published, :archived]
```

### 7. Organize Components in the Configured Namespace

To use the `pom_*` helper methods, define your components in the configured namespace:

```ruby
# app/components/pom/button_component.rb
module Pom
  class ButtonComponent < Pom::Component
    # ...
  end
end
```

## License

The gem is available as open source under the terms of the [MIT License](MIT-LICENSE).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

Created by [Hoang Nghiem](https://github.com/hoangnghiem)
