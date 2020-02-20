;; -*- no-byte-compile: t; -*-
{% do require('this.packages') %}

{% for package in this.packages %}
(package! {{ package }})
{% endfor %}
