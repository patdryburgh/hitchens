# Hitchens

![Hitchens Preview](https://raw.githubusercontent.com/patdryburgh/hitchens/master/assets/images/hitchens-preview.png?token=AAt3Zdd496iHt2EsGaZPS8kiJdtO-D2Zks5babOPwA%3D%3D)

An inarguably well-designed Jekyll theme.

## Installation

Add this line to your Jekyll site's `Gemfile`:

```ruby
gem "hitchens"
```

And add this line to your Jekyll site's `_config.yml`:

```yaml
theme: hitchens
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hitchens

## Usage

### Home Layout

The `home` layout presents a list of articles ordered chronologically. All articles are presented in one page, similar to a book's table of contents.

The masthead of the home page is derived from the `title` and `description` set in your site's `_config.yml` file.

#### Navigation

To include navigation in your site's masthead:

1. Create a `_data` directory in the root of your site.
2. Add a `menu.yml` file to the `_data` directory.
3. Use the following format to list your menu items:

```
- title: About
  url: /about
```

Be sure to start your `url`s with a `/`.


### Post Layout

A sparsely decorated layout designed to present long-form writing in a manner that's pleasing to read.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/patdryburgh/hitchens. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Development

To set up your environment to develop this theme, run `bundle install`.

The theme is setup just like a normal Jekyll site. To test the theme, run `bundle exec jekyll serve` and open your browser at `http://localhost:4000`. This starts a Jekyll server using the theme. Add pages, documents, data, etc. like normal to test the theme's contents. As you make modifications to the theme and to your content, your site will regenerate and you should see the changes in the browser after a refresh, just like normal.

## License

The theme is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

