# BNB AppFormBuilder

The canonical implementation of BNB's custom form builder.

In the past we've often reached for gems like SimpleForm to implement custom form builders. From builder gems are amazing feats of engineering, but they were adding complexity to our apps and another layer of config to learn and manage. We found this in-app form builder approach to be more approachable for our team.

By using an in-app form builder we get a few advantages
- a unified API between all forms at BNB
- a customization point for each app to specify how that app wants it's forms to look
- auto finds the correct input to render each field
- error messages are automatically added to fields


We wrote up a blog post about this form builder here https://brandnewbox.com/notes/2021/03/form-builders-in-ruby/.


## Install

This is a copy and paste library. There's no gem to install, just copy these files into your Rails app and customize from there.

- Add the `app_form_builder.rb` file to the `helpers` folder of the Rails app.
- Add `default_form_builder AppFormBuilder` into your `ApplicationController` class.
- Change the Rails error proc behavior to use a blank error proc so that it doesn't override the error styling of the form. You have 2 options here:
  - Option 1: Change the error proc in your `application.rb` file. This one works well with the `default_form_builder` setting from above.
    ```ruby
    config.action_view.field_error_proc = Proc.new { |tag, instance| tag }
    ```
  - Option 2: Add a custom helper to your `ApplicationHelper`.
    ```ruby
    def app_form_with(*, **, &)
      AppFormBuilder.with_blank_error_proc do
        form_with(*, builder: AppFormBuilder, **, &)
      end
    end
    ```

## Docs

The main entrypoint into the `AppFormBuilder` (drawing inspiration from SimpleForm) is the `input` method.

```ruby
= f.input :method,
    as: # symbol, optional, will default to the type of the attribute. calls #{as}_input in the form builder
    label: # string | false, optional, controls the label text or hides the label
    hint: # string, optional, adds hint text below the input
    collection: # array, triggers the select_input method
    text_method: # symbol, optional, the method to pull the text from the collection
    value_method: # symbol, optional, the method to pull the value from the collection
    input_html: # hash, optional, additional html options for the input. Most inputs accept this and try to intelligently merge existing options with customizations
```

### Examples

```ruby
# Renders a string field if `name` is a string column
= f.input :name
```

```ruby
# Renders a text area with no label
= f.input :name, as: :text, label: false
```

```ruby
# Example of more full featured forms from our code
= f.input :full_name, label: t("full_name").titleize
= f.input :preferred_name, label: t("preferred_name").titleize , hint: t("preferred_name_hint")


= f.fields_for :profile do |f|
  = f.input :work_location, label: t("location"),as: :grouped_select, collection: Profile::WORK_LOCATIONS, group_method: :last, include_blank: t("select_state").titleize, input_html: {style: "color: #808080;"}
  = f.input :tag, label: t("position").titleize, input_html: {placeholder: t("enter_position")}, hint: t("enter_position_long")
  %h4.pb-2=t("optional_info").titleize
  = f.input :organization, label: t("organization").titleize
  = f.input :biography, label: t("biography").titleize, input_html: {placeholder: t("biography_hint")}
  = f.input :language_list, label: t("your_lang").titleize, collection: User::LANGUAGES, input_html: { multiple: true, data:{ controller: "tag", placeholder: t("select_language").titleize } }
```


