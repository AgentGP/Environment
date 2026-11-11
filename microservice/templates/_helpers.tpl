

{{- define "service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "service.labels" -}}
app: {{ include "service.fullname" . }}
{{- range $name, $value := .Values.labels }}
{{ $name }}: {{ $value }}
{{- end }}
{{- end }}

{{- define "service.image" -}}
{{ printf "%s:%s" 
    (.Values.image.repository | required "You must specify .Values.image.repository") 
    ((.Values.image.tag | toString) | default "latest") }}
{{- end }}



{{- define "service.resources" -}}
requests:
{{ printf "memory: %s" .Values.resources.memory | indent 2 }}
{{ printf "cpu: %s" .Values.resources.cpu | indent 2 }}
limits:
{{ printf "memory: %s" .Values.resources.memory | indent 2 }}
{{ printf "cpu: %sm" (mul (atoi (
    trimSuffix "m" ( toString .Values.resources.cpu))) 4  
    | toString ) | indent 2 }}
{{- end -}}
