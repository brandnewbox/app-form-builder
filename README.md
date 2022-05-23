# BNB AppFormBuilder

The canonical implementation of BNB's custom form builder.

By using a unified form builder we get a few advantages
- a unified API between all forms at BNB
- a customization point for each app to specify how that app wants it's forms to look
- auto finds the correct input to render each field
- error messages are automatically added to fields


We wrote up a blog post about this form builder here https://brandnewbox.com/notes/2021/03/form-builders-in-ruby/.


## Install

Our current distribution is by adding the form builder to the `helpers` folder of the Rails app.