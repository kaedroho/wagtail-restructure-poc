from django import template

from .wagtail import pageurl, slugurl, wagtail_version, wagtail_documentation_path, wagtail_release_notes_path, richtext, include_block, wagtail_site


register = template.Library()

register.simple_tag(takes_context=True)(pageurl)
register.simple_tag(takes_context=True)(slugurl)
register.simple_tag(wagtail_version)
register.simple_tag(wagtail_documentation_path)
register.simple_tag(wagtail_release_notes_path)
register.filter(richtext)
register.tag(include_block)
register.simple_tag(takes_context=True)(wagtail_site)
