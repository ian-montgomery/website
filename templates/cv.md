{% set basics = load_data(path="data/basics.json") -%}
{% set jobs = load_data(path="data/jobs.json") -%}
{% set education = load_data(path="data/education.json") -%}
{% set achievements = load_data(path="data/achievements.json") -%}
{% set skills = load_data(path="data/skills.json") -%}
# {{ basics.name }}

**{{ basics.label }}**

{{ basics.email }}{% if basics.phone %} · {{ basics.phone }}{% endif %} · {{ basics.city }}, {{ basics.country }}

{% for social in basics.socials -%}
- [{{ social.label }}]({{ social.url }})
{% endfor %}
{{ basics.summary }}

---

## Work Experience

{% for job in jobs -%}
### {{ job.title }} · [{{ job.organization_pdf | default(value=job.organization) }}]({{ job.org_url }})

*{{ job.start | date(format="%B %Y") }} – {% if job.end %}{{ job.end | date(format="%B %Y") }}{% else %}Present{% endif %} · {{ job.employment_type }} · {{ job.work_model }} · {{ job.location }}*

{% for bullet in job.bullets_pdf -%}
- {{ bullet }}
{% endfor %}
{% if job.skills -%}
**Skills:** {% for sk in job.skills %}{% if skills.all[sk] %}{{ skills.all[sk].name }}{% else %}{{ sk }}{% endif %}{% if not loop.last %}, {% endif %}{% endfor %}
{% endif %}
{%- if not loop.last %}
{% endif %}
{%- endfor %}
---

## Education

{% for edu in education -%}
### {{ edu.title }} · [{{ edu.institution }}]({{ edu.inst_url }})

*{{ edu.start | date(format="%B %Y") }} – {% if edu.end %}{{ edu.end | date(format="%B %Y") }}{% else %}Present{% endif %}{% if edu.mode %} · Mode: {{ edu.mode }}{% endif %}{% if edu.qualification %} · Qualification: {{ edu.qualification }}{% endif %}{% if edu.minor %} · Minor: {{ edu.minor }}{% endif %}*

{{ edu.description }}

{% if edu.skills -%}
**Skills:** {% for sk in edu.skills %}{% if skills.all[sk] %}{{ skills.all[sk].name }}{% else %}{{ sk }}{% endif %}{% if not loop.last %}, {% endif %}{% endfor %}
{% endif %}
{%- if not loop.last %}
{% endif %}
{%- endfor %}
---

## Achievements

{% for achievement in achievements -%}
### {{ achievement.name }}

*{{ achievement.date | date(format="%B %Y") }} · Issued by [{{ achievement.issuer }}]({{ achievement.issuer_url }})*

{{ achievement.description }}

{% endfor %}
