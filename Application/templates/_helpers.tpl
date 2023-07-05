{{- define "app.name" -}}
{{ default .Release.Name .Values.global.nameOverride }}
{{- end -}}

{{- define "app.labels" -}}
helm.sh/chart: {{ .Chart.Name }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.openshift.io/runtime: app
{{- end }}

{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "app.imageName" -}}
{{ default (include "app.name" .) .Values.image.name }}:{{ .Values.image.tag }}
{{- end -}}