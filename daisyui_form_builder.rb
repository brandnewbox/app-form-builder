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
    when :integer then :string
    when :email then :string
    when :telephone then :string
    when :url then :string
    when :datetime_local then :string
    when :password then :string
    when :search then :string
    when :week then :string
    when :month then :string
    when :date then :datetime
    when :time then :datetime
    end

    send("#{override_input_type || input_type}_input", method, options)
  end

  def self.with_blank_error_proc(&block)
    old_error_proc = ActionView::Base.field_error_proc
    begin
      ActionView::Base.field_error_proc = proc do |tag, instance|
        tag
      end
      block.call
    ensure
      ActionView::Base.field_error_proc = old_error_proc
    end
  end

  # def label(method, label = nil, options = {}, &)
  #   super(method, label, merge_input_options({class: "form-label"}, options), &)
  # end

  private

  def form_group(method, options = {}, &block)
    label(method, class: "form-control mb-3") do
      safe_join [
        label_text(method, options[:label], class: "font-bold"),
        block.call,
        hint_text(options[:hint]),
        error_text(method)
      ].compact
    end
  end

  def collection_group(method, options = {}, &block)
    safe_join [
      label_text(method, options[:label], class: "font-bold"),
      block.call,
      hint_text(options[:hint]),
      error_text(method)
    ].compact
  end

  def label_text(method, text = nil, options = {})
    return if text == false
    text ||= method.to_s.humanize
    tag.div(class: "label #{options[:class]}") do
      tag.span(text, class: "label-text")
    end
  end

  def hint_text(text)
    return if text.nil?
    tag.div class: "label" do
      tag.span(text, class: "label-text-alt text-sm")
    end
  end

  def error_text(method)
    return unless has_error?(method)
    tag.div(load_error(method).join("<br />").html_safe, class: "invalid-feedback text-error")
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
      string_field(method, merge_input_options({input_html: {class: "input input-bordered #{"input-error" if has_error?(method)}"}}, options))
    end
  end

  def text_input(method, options = {})
    form_group(method, options) do
      text_area(method, merge_input_options({class: "input input-bordered min-h-20 #{"input-error" if has_error?(method)}"}, options[:input_html]))
    end
  end

  def range_input(method, options = {})
    if (measure_count = options.delete(:measure))
      @measure = tag.div class: "flex justify-between px-2 text-xs" do
        safe_join (measure_count + 1).times.map { tag.span("|") }
      end
    end
    form_group(method, options) do
      safe_join [
        range_field(method, merge_input_options({class: "range #{"input-error" if has_error?(method)}"}, options[:input_html])),
        @measure
      ]
    end
  end

  def boolean_input(method, options = {})
    tag.div(class: "form-control mb-3") do
      safe_join [
        label(method, options[:label], class: "label cursor-pointer py-1 justify-start") {
          safe_join [
            check_box(method, merge_input_options({class: "checkbox me-2"}, options[:input_html])),
            label_text(method, options[:label])
          ]
        },
        hint_text(options[:hint]),
        error_text(method)
      ]
    end
  end

  def color_input(method, options = {})
    tag.div(class: "form-control mb-3") do
      safe_join [
        label(method, options[:label], class: "label cursor-pointer p-0 justify-start") {
          safe_join [
            color_field(method, merge_input_options({class: "input p-0 me-2 border-none"}, options[:input_html])),
            label_text(method, options[:label])
          ]
        },
        hint_text(options[:hint]),
        error_text(method)
      ]
    end
  end

  def toggle_input(method, options = {})
    tag.div(class: "form-control mb-3") do
      safe_join [
        label(method, options[:label], class: "label cursor-pointer p-0 justify-start") {
          safe_join [
            check_box(method, merge_input_options({class: "toggle  me-2"}, options[:input_html])),
            label_text(method, options[:label])
          ]
        },
        error_text(method)
      ]
    end
  end

  def collection_input(method, options, &block)
    form_group(method, options) do
      block.call
    end
  end

  def select_input(method, options = {})
    value_method = options[:value_method] || :to_s
    text_method = options[:text_method] || :to_s

    collection_input(method, options) do
      collection_select(method, options[:collection], value_method, text_method, options, merge_input_options({class: "select select-bordered #{"is-invalid" if has_error?(method)}"}, options[:input_html]))
    end
  end

  def grouped_select_input(method, options = {})
    # We probably need to go back later and adjust this for more customization
    collection_input(method, options) do
      grouped_collection_select(method, options[:collection], :last, :first, :to_s, :to_s, options, merge_input_options({class: "select select-bordered #{"is-invalid" if has_error?(method)}"}, options[:input_html]))
    end
  end

  def datetime_input(method, options = {})
    input_builder_method = case options[:as]
    when :date then :date_select
    when :datetime then :datetime_select
    when :time then :time_select
    end
    collection_input(method, options) do
      tag.div class: "flex gap-2 items-center" do
        send(
          input_builder_method,
          method,
          merge_input_options({}, options[:options]),
          merge_input_options({class: "select select-bordered #{"is-invalid" if has_error?(method)}"}, options[:input_html])
        )
      end
    end
  end

  def file_input(method, options = {})
    form_group(method, options) do
      file_field(method, merge_input_options({class: "file-input file-input-bordered"}, options[:input_html]))
    end
  end

  def collection_of(input_type, method, options = {})
    form_builder_method, custom_class, input_builder_method = case input_type
    when :radio_buttons then [:collection_radio_buttons, "radio me-2", :radio_button]
    when :check_boxes then [:collection_check_boxes, "checkbox me-2", :check_box]
    when :toggles then [:collection_check_boxes, "toggle me-2", :check_box]
    else raise "Invalid input_type for collection_of, valid input_types are \":radio_buttons\", \":check_boxes\""
    end

    collection_group(method, options) do
      send(form_builder_method, method, options[:collection], options[:value_method], options[:text_method]) do |b|
        tag.div(class: "form-control") do
          safe_join [
            label(b, for: nil, class: "label cursor-pointer py-1 justify-start") {
              safe_join [
                b.send(input_builder_method, merge_input_options({class: custom_class}, options[:input_html])),
                label_text(method, b.text)
              ]
            }
          ]
        end
      end
    end
  end

  def radio_buttons_input(method, options = {})
    collection_of(:radio_buttons, method, options)
  end

  def check_boxes_input(method, options = {})
    collection_of(:check_boxes, method, options)
  end

  def toggles_input(method, options = {})
    collection_of(:toggles, method, options)
  end

  def string_field(method, options = {})
    html_options = options[:input_html]
    case options[:as] || object_type_for_method(method)
    when :integer then number_field(method, html_options)
    when :email then email_field(method, html_options)
    when :telephone then telephone_field(method, html_options)
    when :url then url_field(method, html_options)
    when :datetime_local then datetime_local_field(method, html_options)
    when :password then password_field(method, html_options)
    when :search then search_field(method, html_options)
    when :week then week_field(method, html_options)
    when :month then month_field(method, html_options)
    when :string
      case method.to_s
      when /password/ then password_field(method, html_options)
      # when /time_zone/ then :time_zone
      # when /country/   then :country
      when /email/ then email_field(method, html_options)
      when /phone/ then phone_field(method, html_options)
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
