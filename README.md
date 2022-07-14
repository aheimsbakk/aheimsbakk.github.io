# Notes on my blog

* Generator: https://gohugo.io/
* Theme: https://github.com/nodejh/hugo-theme-mini
* Social icons override: https://www.svgrepo.com/collection/tech-brand-logos/1

    Overriden in `layouts/partials/svgs`. Changed the heading of the SVG to get correct size and color as follows.
    ```jinja
    <svg fill="{{ .fill }}" width="{{ .width }}" height="{{ .height }}" \>
      ```
* Misc CSS overrides in `static/css`.
