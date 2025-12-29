{{- define "aiops.name" -}}
aiops-api
{{- end }}

{{- define "aiops.fullname" -}}
{{ include "aiops.name" . }}
{{- end }}
