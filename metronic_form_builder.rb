# For use with the Metronic template https://keenthemes.com/metronic

class AppFormBuilder < ActionView::Helpers::FormBuilder
    include MetronicHelper
    include ActionView::Helpers::OutputSafetyHelper
    delegate :tag, :safe_join, to: :@template
    
    def input(method, options = {})
      object_type = object_type_for_method(method)
  
      input_type = case object_type
      when :date then :string
      when :datetime then :string
      when :integer then :string
      when :decimal then :string
      when :float then :string
      when :binary then :file
      else object_type
      end
  
      override_input_type = if options[:as]
        options[:as]
      elsif options[:collection]
        :select
      end
  
      send("#{override_input_type || input_type}_input", method, options)
    end
  
    def submit(text, options = {})
      default_options = {
        class: "btn btn-primary"
      }
      options = default_options.merge(options).symbolize_keys
      super(text, options)
    end
  
    private
  
    def input_layout_classes
      ""
    end
    
    def label_layout_classes
      ""
    end
  
    def form_group(method, options = {}, &block)
      group_html = options[:group_html] ||= {}
      tag.div class: ["mb-5", method, group_html[:class]] do
        block.call
      end
    end
  
    # A majority of our inputs have this floating form style however not
    # every input uses it so we'll create a wrapper around the base
    # form input to make it easier to share the logic of a
    # "floating group"
    def floating_form_group(method, options = {}, &block)
      form_group(method, merge_input_options({group_html: {class: "form-floating"}}, options), &block)
    end
  
    def input_wrap(content, opts = {})
      tag.div(content, class: "#{input_layout_classes} #{opts[:class]}")
    end
  
    def hint_text(text)
      return if text.nil?
      tag.div text, class: "form-text"
    end
  
    def error_text(method)
      return unless has_error?(method)
  
      tag.div(@object.errors[method].join("<br />").html_safe, class: "invalid-feedback")
    end
  
    def object_type_for_method(method)
      result = if @object.respond_to?(:type_for_attribute) && @object.has_attribute?(method)
        @object.type_for_attribute(method.to_s).try(:type)
      elsif @object.respond_to?(:column_for_attribute) && @object.has_attribute?(method)
        @object.column_for_attribute(method).try(:type)
      elsif @object.class.respond_to?(:attribute_types) && @object.class.attribute_types.has_key?(method.to_s)
        @object.class.attribute_types[method.to_s].try(:type)
      end
  
      result || :string
    end
  
    def has_error?(method)
      return false unless @object.respond_to?(:errors)
      @object.errors.key?(method)
    end
  
    def label(method, text = nil, options = {}, &block)
      class_names = ["col-form-label", label_layout_classes, validation_class_name(method)]
      options = merge_input_options({class: class_names.join(" ")}, options)
      super(method, text, options, &block)
    end
  
    # Inputs and helpers
  
    def string_input(method, options = {})
      floating_form_group(method, options) do
        safe_join [
          string_field(method, merge_input_options({class: "form-control #{"is-invalid" if has_error?(method)}", placeholder: "Placeholder"}, options[:input_html])),
          (label(method, options[:label]) unless options[:label] == false),
          hint_text(options[:hint]),
          error_text(method)
        ].compact
      end
    end
  
    def text_input(method, options = {})
      floating_form_group(method, options) do
        safe_join [
          text_area(method, merge_input_options({class: "form-control #{"is-invalid" if has_error?(method)}", placeholder: "Placeholder"}, options[:input_html])),
          (label(method, options[:label]) unless options[:label] == false),
          hint_text(options[:hint]),
          error_text(method)
        ].compact
      end
    end
  
    def boolean_input(method, options = {})
      unchecked_value = if options[:unchecked_value] == false
        nil # If we explicitly pass false, then don't provide an unchecked value
      elsif options[:unchecked_value] == nil
        "0" # If we don't pass a value, then use the default of "0"
      else
        options[:unchecked_value] # Everything else: Use the option passed
      end
      form_group(method, options) do
        tag.div(class: "form-check") do
          safe_join [
            check_box(method, merge_input_options({class: "form-check-input #{"is-invalid" if has_error?(method)}"}, options[:input_html]), (options[:checked_value] || "1"), unchecked_value),
            label(method, options[:label], class: "form-check-label"),
            hint_text(options[:hint]),
            error_text(method),
          ].compact
        end
      end
    end
  
    def collection_input(method, options, &block)
      floating_form_group(method, options) do
        safe_join [
          block.call,
          (label(method, options[:label]) unless options[:label] == false),
          hint_text(options[:hint]),
          error_text(method)
        ]
      end
    end
  
    def select2_input(method, options = {})
      options[:input_html] ||= {}
      options[:input_html][:data] ||= {}
      options[:input_html][:data][:control] = 'select2'
      select_input(method, options)
    end
  
    def select_input(method, options = {})
      value_method = options[:value_method] || :to_s
      text_method = options[:text_method] || :to_s
      input_options = options[:input_html] || {}
      multiple = input_options[:multiple]
  
      if multiple
        default_options = {
          data: {control: "select2", placeholder: 'Select an option', allow_clear: "true", close_on_select: 'false'}
        }
        options[:input_html] = default_options.merge(options[:input_html]).symbolize_keys
      end
      
      collection_input(method, options) do
        collection_select(method, options[:collection], value_method, text_method, options, merge_input_options({class: "#{"custom-select" unless multiple} form-select #{"is-invalid" if has_error?(method)}"}, options[:input_html]))
      end
    end
  
    def grouped_select_input(method, options = {})
      # We probably need to go back later and adjust this for more customization
      collection_input(method, options) do
        grouped_collection_select(method, options[:collection], :last, :first, :to_s, :to_s, options, merge_input_options({class: "custom-select form-control #{"is-invalid" if has_error?(method)}"}, options[:input_html]))
      end
    end
  
    def file_input(method, options = {})
      floating_form_group(method, options) do
        safe_join [
          custom_file_field(method, options),
          (label(method, options[:label]) unless options[:label] == false)
        ].compact
      end
    end
  
    def number_input(method, options = {})
      floating_form_group(method, options) do
        safe_join [
          number_field(method, merge_input_options({class: "form-control #{"is-invalid" if has_error?(method)}"}, options[:input_html])),
          (label(method, options[:label]) unless options[:label] == false),
          hint_text(options[:hint]),
          error_text(method)
        ].compact
      end
    end
  
    def image_input(method, options = {})
      class_name = options[:current_url] ? "" : "image-input-empty"
  
      options[:default_url] ||= "https://via.placeholder.com/120x120"
      image_url_style = options[:current_url] ? "url(#{options[:current_url]})" : "none"
  
      floating_form_group(method, options) do
        safe_join [
          label(method, options[:label]),
          tag.div(class: "col-lg-9") {
            safe_join [
              tag.div(class: "image-input image-input-outline #{class_name}", data: {"kt-image-input": true}, style: "background-image: url(#{options[:default_url]})") {
                a = [
                  tag.div(class: "image-input-wrapper w-125px h-125px", style: image_url_style),
                  tag.label(
                    class: "btn btn-icon btn-circle btn-active-color-primary w-25px h-25px bg-white shadow",
                    data: {
                      "kt-image-input-action": "change",
                      "bs-toggle": "tooltip",
                      "bs-dismiss": "click"
                    },
                    title: "Change"
                  ) {
                    safe_join [
                      metronic_svg("General/Clip"),
                      file_field(method, accept: ".png, .jpg, .jpeg"),
                      hidden_field("remove_#{method}")
                    ]
                  },
                  tag.label(
                    class: "btn btn-icon btn-circle btn-active-color-primary w-25px h-25px bg-white shadow",
                    data: {
                      "kt-image-input-action": "cancel",
                      "bs-toggle": "tooltip",
                      "bs-dismiss": "click"
                    },
                    title: "Cancel"
                  ) {
                    metronic_svg("Navigation/Close")
                  },
                  tag.label(
                    class: "btn btn-icon btn-circle btn-active-color-primary w-25px h-25px bg-white shadow",
                    data: {
                      "kt-image-input-action": "remove",
                      "bs-toggle": "tooltip",
                      "bs-dismiss": "click"
                    },
                    title: "Remove"
                  ) {
                    metronic_svg("Navigation/Close")
                  }
                ]
                safe_join a
              },
              hint_text(options[:hint])
            ]
          }
        ]
      end
    end
  
    def collection_of(input_type, method, options = {})
      form_builder_method, wrapper_class, input_builder_method, label_class, input_class = case input_type
      when :radio_buttons then [:collection_radio_buttons, "form-check mb-2", :radio_button, "form-check-label", "form-check-input"]
      when :check_boxes then [:collection_check_boxes, "form-check mb-2", :check_box, "form-check-label", "form-check-input"]
      else raise "Invalid input_type for collection_of, valid input_types are \":radio_buttons\", \":check_boxes\""
      end
  
      form_group(method, options) do
        safe_join [
          label(method, options[:label]),
          input_wrap(send(form_builder_method, method, options[:collection], options[:value_method], options[:text_method]) do |b|
            tag.div(class: wrapper_class) {
              safe_join [
                b.send(input_builder_method, class: input_class),
                b.label(class: label_class),
              ]
            }
          end),
        ]
      end
    end
  
    def radio_buttons_input(method, options = {})
      collection_of(:radio_buttons, method, options)
    end
  
    def check_boxes_input(method, options = {})
      collection_of(:check_boxes, method, options)
    end
  
    def string_field(method, options = {})
      case object_type_for_method(method)
      when :date
        safe_join [
          date_field(method, merge_input_options(options, {placeholder: "Pick Date", data: {controller: "flatpickr-calendar"}})),
        ]
      when :datetime
        safe_join [
          datetime_field(method, merge_input_options(options, {placeholder: "Pick a Date and Time", data: {controller: "flatpickr-calendar", flatpickr_calendar_time: true}})),
        ]
      when :integer then number_field(method, options)
      when :string, :text, :decimal, :float
        case method.to_s
        when /password/ then password_field(method, options)
        # when /time_zone/ then :time_zone
        # when /country/   then :country
        when /email/ then email_field(method, options)
        when /phone/ then telephone_field(method, options)
        when /url/ then url_field(method, options)
        else
          text_field(method, options)
        end
      end
    end
  
    def custom_file_field(method, options = {})
      file_field(method, options.merge(class: "form-control #{"is-invalid" if has_error?(method)}", data: {controller: "file-input"})) +
        hint_text(options[:hint]) +
        error_text(method)
    end
  
    def merge_input_options(options, user_options)
      return options if user_options.nil?
  
      # TODO handle class merging here
      options.merge(user_options)
    end
  
    def validation_class_name(method)
      return unless @object
      # Taken from Simple Form
      attribute_validators = @object.class.validators_on(method)
      reflection = @object.class.reflect_on_association(method) if @object.class.respond_to?(:reflect_on_association)
      reflection_validators = reflection ? @object.class.validators_on(reflection.name) : []
      required = (attribute_validators + reflection_validators).any? { |v| v.kind == :presence } # && valid_validator?(v) }
      # The empty string makes it easy if we ever
      # want to add back in Metronic's required red
      # asterisk behavior.
      required ? "" : "optional"
    end
  end