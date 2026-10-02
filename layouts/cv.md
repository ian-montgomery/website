{{- $basics := hugo.Data.basics -}}
{{- $skills := hugo.Data.skills -}}
{{- $jobs := hugo.Data.jobs -}}
{{- $education := hugo.Data.education -}}
{{- $achievements := hugo.Data.achievements -}}
{{- $phone := "" -}}
{{- if fileExists "local/private.json" -}}
{{- $private := os.ReadFile "local/private.json" | transform.Unmarshal -}}
{{- $phone = $private.phone -}}
{{- end -}}
# {{ $basics.name }}

**{{ $basics.label }}**

{{ $basics.email }}{{ with $phone }} · {{ . }}{{ end }} · {{ $basics.city }}, {{ $basics.country }}

{{ range $basics.socials -}}
- [{{ .label }}]({{ .url }})
{{ end }}
{{ $basics.summary }}

---

## Skills

{{ range $cat := $skills.categories -}}
**{{ $cat.name }}:** {{ delimit (partial "skill-names.html" $cat.skills) ", " }}

{{ end }}---

## Work Experience

{{ range $job := $jobs -}}
### {{ $job.title }} · [{{ $job.organization_pdf | default $job.organization }}]({{ $job.org_url }})

*{{ (time.AsTime $job.start).Format "January 2006" }} – {{ if $job.end }}{{ (time.AsTime $job.end).Format "January 2006" }}{{ else }}Present{{ end }} · {{ $job.employment_type }} · {{ $job.work_model }} · {{ $job.location }}*

{{ range $job.bullets_pdf -}}
- {{ . }}
{{ end }}
{{ if $job.skills -}}
**Skills:** {{ delimit (partial "skill-names.html" $job.skills) ", " }}

{{ end }}
{{- end }}
---

## Education

{{ range $edu := $education -}}
### {{ $edu.title }} · [{{ $edu.institution }}]({{ $edu.inst_url }})

*{{ (time.AsTime $edu.start).Format "January 2006" }} – {{ if $edu.end }}{{ (time.AsTime $edu.end).Format "January 2006" }}{{ else }}Present{{ end }}{{ with $edu.mode }} · Mode: {{ . }}{{ end }}{{ with $edu.qualification }} · Qualification: {{ . }}{{ end }}{{ with $edu.minor }} · Minor: {{ . }}{{ end }}*

{{ $edu.description }}

{{ if $edu.skills -}}
**Skills:** {{ delimit (partial "skill-names.html" $edu.skills) ", " }}

{{ end }}
{{- end }}
---

## Achievements

{{ range $achievement := $achievements -}}
### {{ $achievement.name }}

*{{ (time.AsTime $achievement.date).Format "January 2006" }} · Issued by [{{ $achievement.issuer }}]({{ $achievement.issuer_url }})*

{{ $achievement.description }}

{{ end }}
