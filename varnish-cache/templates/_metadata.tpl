{{/* vim: set filetype=mustache: */}}

{{/*
Common labels
*/}}
{{- define "varnish-cache.labels" -}}
helm.sh/chart: {{ include "varnish-cache.chart" . }}
{{ include "varnish-cache.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "varnish-cache.selectorLabels" -}}
app.kubernetes.io/name: {{ include "varnish-cache.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "varnish-cache.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "varnish-cache.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Sets up the common server extra annotations
*/}}
{{- define "varnish-cache.serverAnnotations" -}}
{{- if .Values.server.annotations }}
annotations:
  {{- $tp := typeOf .Values.server.annotations }}
  {{- if eq $tp "string" }}
    {{- tpl .Values.server.annotations . | trim | nindent 2 }}
  {{- else }}
    {{- toYaml .Values.server.annotations | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Sets up the common server extra labels
*/}}
{{- define "varnish-cache.serverLabels" -}}
{{- if .Values.server.labels }}
{{- $tp := typeOf .Values.server.labels }}
{{- if eq $tp "string" }}
  {{- tpl .Values.server.labels . | trim | nindent 0 }}
{{- else }}
  {{- toYaml .Values.server.labels | nindent 0 }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Sets up the common service extra annotations
*/}}
{{- define "varnish-cache.serviceAnnotations" -}}
{{- if .Values.server.service.annotations }}
annotations:
  {{- $tp := typeOf .Values.server.service.annotations }}
  {{- if eq $tp "string" }}
    {{- tpl .Values.server.service.annotations . | trim | nindent 2 }}
  {{- else }}
    {{- toYaml .Values.server.service.annotations | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Sets up the common service extra labels
*/}}
{{- define "varnish-cache.serviceLabels" -}}
{{- $section := default "server" .section -}}
{{- $service := (get .Values $section).service -}}
{{- if $service.labels -}}
{{- $tp := typeOf $service.labels -}}
{{- if eq $tp "string" -}}
{{- tpl $service.labels . | trim | nindent 0 }}
{{- else -}}
{{- toYaml $service.labels | trim | nindent 0 }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Sets up the common ingress extra annotations
*/}}
{{- define "varnish-cache.ingressAnnotations" -}}
{{- $section := default "server" .section -}}
{{- $ingress := (get .Values $section).ingress -}}
{{- if $ingress.annotations }}
annotations:
  {{- $tp := typeOf $ingress.annotations }}
  {{- if eq $tp "string" }}
    {{- tpl $ingress.annotations . | trim | nindent 2 }}
  {{- else }}
    {{- toYaml $ingress.annotations | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Sets up the common ingress extra labels
*/}}
{{- define "varnish-cache.ingressLabels" -}}
{{- $section := default "server" .section -}}
{{- $ingress := (get .Values $section).ingress -}}
{{- if $ingress.labels }}
{{- $tp := typeOf $ingress.labels }}
{{- if eq $tp "string" }}
  {{- tpl $ingress.labels . | trim | nindent 0 }}
{{- else }}
  {{- toYaml $ingress.labels | nindent 0 }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Sets up the common service account annotations
*/}}
{{- define "varnish-cache.serviceAccountAnnotations" -}}
{{- if .Values.serviceAccount.annotations }}
annotations:
  {{- $tp := typeOf .Values.serviceAccount.annotations }}
  {{- if eq $tp "string" }}
    {{- tpl .Values.serviceAccount.annotations . | trim | nindent 2 }}
  {{- else }}
    {{- toYaml .Values.serviceAccount.annotations | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Sets up the common service account extra labels
*/}}
{{- define "varnish-cache.serviceAccountLabels" -}}
{{- if .Values.serviceAccount.labels }}
{{- $tp := typeOf .Values.serviceAccount.labels }}
{{- if eq $tp "string" }}
  {{- tpl .Values.serviceAccount.labels . | trim | nindent 0 }}
{{- else }}
  {{- toYaml .Values.serviceAccount.labels | nindent 0 }}
{{- end }}
{{- end }}
{{- end }}