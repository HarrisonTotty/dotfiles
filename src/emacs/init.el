{% do require('this.module_groups') %}

(doom! :input

{% for group in this.module_groups %}
{% if not group.name is defined%}
{% do raise('one or more module groups do not specify a name') %}
{% endif %}
{% if not group.modules is defined %}
{% do raise('one ore more module groups do not specify a list of modules') %}
{% endif %}
       :{{ group.name }}
{% for m in group.modules %}
       {{ m }}
{% endfor %}

{% endfor %}
)
