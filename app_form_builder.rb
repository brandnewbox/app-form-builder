# To be used with Bootstrap 5

class AppFormBuilder < ActionView::Helpers::FormBuilder
  delegate :tag, :safe_join, to: :@template

  def input(method, options = {})
    @form_options = options
    object_type = object_type_for_method(method)

    input_type = if options[:as]
      options[:as]
    elsif options[:collection]
      :select
    else
      object_type
    end

    override_input_type = case input_type
    when :date then :string
    when :integer then :string
    end

    send("#{override_input_type || input_type}_input", method, options)
  end

  def self.with_blank_error_proc(&block)
    old_error_proc = ActionView::Base.field_error_proc
    begin
      ActionView::Base.field_error_proc = Proc.new do |tag, instance|
        tag
      end
      block.call
    ensure
      ActionView::Base.field_error_proc = old_error_proc
    end
  end

  def label(method, label = nil, options = {})
    super(method, label, merge_input_options({class: "form-label"}, options))
  end

  private

  def form_group(method, options = {}, &block)
    tag.div class: "mb-3 #{method}" do
      safe_join [
        block.call,
        hint_text(options[:hint]),
        error_text(method),
      ].compact
    end
  end

  def hint_text(text)
    return if text.nil?
    tag.small text, class: "form-text text-muted"
  end

  def error_text(method)
    return unless has_error?(method)

    tag.div(load_error(method).join("<br />").html_safe, class: "invalid-feedback")
  end

  def has_error?(method)
    return false unless @object.respond_to?(:errors)
    association = find_association(method)
    normalized_method = association ? association.name : method
    @object.errors.key?(normalized_method)
  end
  
  def load_error(method)
    association = find_association(method)
    normalized_method = association ? association.name : method
    @object.errors[normalized_method]
  end

  def object_type_for_method(method)
    result = if @object.respond_to?(:type_for_attribute) && @object.has_attribute?(method)
      @object.type_for_attribute(method.to_s).try(:type)
    elsif @object.respond_to?(:column_for_attribute) && @object.has_attribute?(method)
      @object.column_for_attribute(method).try(:type)
    end

    result || :string
  end

  # Inputs and helpers

  def string_input(method, options = {})
    form_group(method, options) do
      safe_join [
        (label(method, options[:label]) unless options[:label] == false),
        string_field(method, merge_input_options({input_html: {class: "form-control #{"is-invalid" if has_error?(method)}"}}, options)),
      ]
    end
  end

  def text_input(method, options = {})
    form_group(method, options) do
      safe_join [
        (label(method, options[:label]) unless options[:label] == false),
        text_area(method, merge_input_options({class: "form-control #{"is-invalid" if has_error?(method)}"}, options[:input_html])),
      ]
    end
  end

  def boolean_input(method, options = {})
    form_group(method, options) do
      tag.div(class: "form-check") do
        safe_join [
          check_box(method, merge_input_options({class: "form-check-input"}, options[:input_html])),
          label(method, options[:label], class: "form-check-label"),
        ]
      end
    end
  end

  def collection_input(method, options, &block)
    form_group(method, options) do
      safe_join [
        label(method, options[:label]),
        block.call,
      ]
    end
  end

  def select_input(method, options = {})
    value_method = options[:value_method] || :to_s
    text_method = options[:text_method] || :to_s
    input_options = options[:input_html] || {}

    multiple = input_options[:multiple]

    collection_input(method, options) do
      collection_select(method, options[:collection], value_method, text_method, options, merge_input_options({class: "#{"custom-select" unless multiple} form-control #{"is-invalid" if has_error?(method)}"}, options[:input_html]))
    end
  end

  def grouped_select_input(method, options = {})
    # We probably need to go back later and adjust this for more customization
    collection_input(method, options) do
      grouped_collection_select(method, options[:collection], :last, :first, :to_s, :to_s, options, merge_input_options({class: "custom-select form-control #{"is-invalid" if has_error?(method)}"}, options[:input_html]))
    end
  end

  def file_input(method, options = {})
    form_group(method, options) do
      safe_join [
        (label(method, options[:label]) unless options[:label] == false),
        file_field(method, merge_input_options({class: "form-control"}, options))
      ]
    end
  end

  def collection_of(input_type, method, options = {})
    form_builder_method, custom_class, input_builder_method = case input_type
    when :radio_buttons then [:collection_radio_buttons, "custom-radio", :radio_button]
    when :check_boxes then [:collection_check_boxes, "custom-checkbox", :check_box]
    else raise "Invalid input_type for collection_of, valid input_types are \":radio_buttons\", \":check_boxes\""
    end

    form_group(method, options) do
      safe_join [
        label(method, options[:label]),
        tag.br,
        (send(form_builder_method, method, options[:collection], options[:value_method], options[:text_method]) do |b|
          tag.div(class: "custom-control #{custom_class}") {
            safe_join [
              b.send(input_builder_method, class: "custom-control-input"),
              b.label(class: "custom-control-label"),
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
    html_options = options[:input_html]
    case options[:as] || object_type_for_method(method)
    when :date then
      birthday = method.to_s =~ /birth/
      safe_join [
        date_field(method, merge_input_options(html_options, {data: {datepicker: true}})),
        tag.div {
          date_select(method, {
            order: [:month, :day, :year],
            start_year: birthday ? 1900 : Date.today.year - 5,
            end_year: birthday ? Date.today.year : Date.today.year + 5,
          }, {data: {date_select: true}})
        },
      ]
    when :integer then number_field(method, html_options)
    when :string
      case method.to_s
      when /password/ then password_field(method, html_options)
      # when /time_zone/ then :time_zone
      # when /country/   then :country
      when /email/ then email_field(method, html_options)
      when /phone/ then telephone_field(method, html_options)
      when /url/ then url_field(method, html_options)
      else
        text_field(method, html_options)
      end
    else
      text_field(method, html_options)
    end
  end

  def merge_input_options(options, user_options)
    return options if user_options.nil?

    options.deep_merge(user_options) do |key, val1, val2|
      # When we pass in classes or stimulus related attributes we will try to merge them by concatenation rather than overwriting.
      if [:action, :controller, :class].include?(key)
        @template.token_list(val1, val2)
      else
        val2
      end
    end
  end

  def find_association(method)
    # Converts the method #author_id to #author in order to look up the association
    object.class.reflect_on_association(method.to_s.gsub("_id", "").to_sym)
  end
end
