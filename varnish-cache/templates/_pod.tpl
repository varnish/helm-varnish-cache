{{/*
Sets up nodeSelector depending on whether a YAML map or a string is given.
*/}}
{{- define "varnish-cache.nodeSelector" -}}
{{- if .Values.server.nodeSelector }}
nodeSelector:
  {{- $tp := kindOf .Values.server.nodeSelector }}
  {{- if eq $tp "string" }}
    {{- tpl .Values.server.nodeSelector . | trim | nindent 2 }}
  {{- else }}
    {{- toYaml .Values.server.nodeSelector | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Sets up Pod labels
*/}}
{{- define "varnish-cache.podLabels" }}
labels:
  {{- include "varnish-cache.selectorLabels" . | nindent 2 }}
  {{- if .Values.server.podLabels }}
  {{- $tp := kindOf .Values.server.podLabels }}
  {{- if eq $tp "string" }}
    {{- tpl .Values.server.podLabels . | trim | nindent 2 }}
  {{- else }}
    {{- toYaml .Values.server.podLabels | nindent 2 }}
  {{- end }}
  {{- end }}
{{- end }}

{{/*
Sets up Pod annotations
*/}}
{{- define "varnish-cache.podAnnotations" }}
{{- $defaultVcl := osBase .Values.server.vclConfigPath }}
{{- $vclConfig := include "varnish-cache.vclConfig" . }}
{{- $cmdfileConfig := include "varnish-cache.cmdfileConfig" . }}
{{- $secretConfig := include "varnish-cache.secretConfig" . }}
annotations:
  {{- if .Values.server.podAnnotations }}
  {{- $tp := kindOf .Values.server.podAnnotations }}
  {{- if eq $tp "string" }}
    {{- tpl .Values.server.podAnnotations . | trim | nindent 2 }}
  {{- else }}
    {{- toYaml .Values.server.podAnnotations | nindent 2 }}
  {{- end }}
  {{- end }}
  {{- if not (eq $vclConfig "") }}
  checksum/{{ .Release.Name }}-vcl: {{ $vclConfig | sha256sum }}
  {{- end }}
  {{- $vclConfigs := omit .Values.server.vclConfigs $defaultVcl }}
  {{- if not (empty $vclConfigs) }}
  {{- range $k, $v := $vclConfigs }}
  checksum/{{ $.Release.Name }}-vcl-{{ regexReplaceAll "\\W+" $k "-" }}: {{ tpl $v $ | sha256sum }}
  {{- end }}
  {{- end }}
  {{- if not (eq $cmdfileConfig "") }}
  checksum/{{ .Release.Name }}-cmdfile: {{ $cmdfileConfig | sha256sum }}
  {{- end }}
  {{- if not (eq $secretConfig "") }}
  checksum/{{ .Release.Name }}-secret: {{ $secretConfig | sha256sum }}
  {{- end }}
  {{- $extraManifests := .Values.extraManifests }}
  {{- if not (empty $extraManifests) }}
  {{- range $v := $extraManifests }}
  {{- if default false $v.checksum }}
  {{- $tp := kindOf $v.data }}
  {{- if eq $tp "string" }}
  checksum/{{ $.Release.Name }}-extra-{{ $v.name }}: {{ tpl $v.data $ | sha256sum }}
  {{- else }}
  checksum/{{ $.Release.Name }}-extra-{{ $v.name }}: {{ toJson $v.data | sha256sum }}
  {{- end }}
  {{- end }}
  {{- end }}
  {{- end }}
{{- end }}

{{/*
Sets up Pod affinity depending on whether a YAML map or a string is given.
*/}}
{{- define "varnish-cache.affinity" -}}
{{- if .Values.server.affinity }}
affinity:
  {{- $tp := kindOf .Values.server.affinity }}
  {{- if eq $tp "string" }}
    {{- tpl .Values.server.affinity . | trim | nindent 2 }}
  {{- else }}
    {{- toYaml .Values.server.affinity | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Sets up Pod tolerations depending on whether a YAML map or a string is given.
*/}}
{{- define "varnish-cache.tolerations" -}}
{{- if .Values.server.tolerations }}
tolerations:
  {{- $tp := kindOf .Values.server.tolerations }}
  {{- if eq $tp "string" }}
    {{- tpl .Values.server.tolerations . | trim | nindent 2 }}
  {{- else }}
    {{- toYaml .Values.server.tolerations | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Sets up terminationGracePeriodSeconds based on whether there's an explicit
terminationGracePeriodSeconds, or 60 seconds after delayedHaltSeconds if
present.
*/}}
{{- define "varnish-cache.terminationGracePeriodSeconds" -}}
{{- if not (empty .Values.server.terminationGracePeriodSeconds) }}
terminationGracePeriodSeconds: {{ .Values.server.terminationGracePeriodSeconds }}
{{- else if not (empty .Values.server.delayedHaltSeconds) }}
terminationGracePeriodSeconds: {{ add .Values.server.delayedHaltSeconds 60 }}
{{- end }}
{{- end }}

{{/*
Declares the Pod's imagePullSecrets
*/}}
{{- define "varnish-cache.podImagePullSecrets" }}
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Declares the Pod's serviceAccount.
*/}}
{{- define "varnish-cache.podServiceAccount" }}
serviceAccountName: {{ include "varnish-cache.serviceAccountName" . }}
{{- end }}

{{/*
Declares the Pod's securityContext.
*/}}
{{- define "varnish-cache.podSecurityContext" }}
{{- if not (empty .Values.global.podSecurityContext) }}
securityContext:
  {{- toYaml .Values.global.podSecurityContext | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Declares the Pod's volume mounts.
*/}}
{{- define "varnish-cache.podVolumes" }}
{{- $defaultVcl := osBase .Values.server.vclConfigPath }}
volumes:
- name: {{ .Release.Name }}-config
  emptyDir:
    medium: "Memory"
{{- if and (not (empty .Values.server.secretFrom)) (not (eq .Values.server.secret "")) }}
{{- fail "Either 'server.secret' or 'server.secretFrom' can be set." }}
{{- else if and (not (empty .Values.server.secretFrom)) }}
{{- if or (not (hasKey .Values.server.secretFrom "name")) (eq .Values.server.secretFrom.name "") }}
{{- fail "'server.secretFrom' must contain a 'name' key." }}
{{- end }}
{{- if or (not (hasKey .Values.server.secretFrom "key")) (eq .Values.server.secretFrom.key "") }}
{{- fail "'server.secretFrom' must contain a 'key' key." }}
{{- end }}
- name: {{ .Release.Name }}-config-secret
  secret:
    secretName: {{ .Values.server.secretFrom.name | quote }}
{{- else if not (eq (include "varnish-cache.secretConfig" .) "") }}
- name: {{ .Release.Name }}-config-secret
  secret:
    secretName: {{ include "varnish-cache.fullname" . }}-secret
{{- end }}
{{- if not (eq (include "varnish-cache.vclConfig" .) "") }}
- name: {{ .Release.Name }}-config-vcl
  configMap:
    name: {{ include "varnish-cache.fullname" . }}-vcl
{{- end }}
{{- $vclConfigs := omit .Values.server.vclConfigs $defaultVcl }}
{{- if not (empty $vclConfigs) }}
{{- range $k, $v := $vclConfigs }}
- name: {{ $.Release.Name }}-config-vcl-{{ regexReplaceAll "\\W+" $k "-" }}
  configMap:
    name: {{ include "varnish-cache.fullname" $ }}-vcl-{{ regexReplaceAll "\\W+" $k "-" }}
{{- end }}
{{- end }}
{{- if not (eq (include "varnish-cache.cmdfileConfig" .) "") }}
- name: {{ .Release.Name }}-config-cmdfile
  configMap:
    name: {{ include "varnish-cache.fullname" . }}-cmdfile
{{- end }}
- name: {{ .Release.Name }}-varnish-vsm
  emptyDir:
    medium: "Memory"
{{- if .Values.server.extraVolumes }}
  {{- $tp := kindOf .Values.server.extraVolumes }}
  {{- if eq $tp "string" }}
    {{- tpl .Values.server.extraVolumes . | trim | nindent 0 }}
  {{- else }}
    {{- toYaml .Values.server.extraVolumes | nindent 0 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Declares the probe for Varnish Cache pod
*/}}
{{- define "varnish-cache.varnishPodProbe" }}
{{- $section := default "server" .section }}
{{- $probeName := .probeName }}
{{- $probe := (get (get .Values $section) $probeName) }}
{{- if and $probe (not (empty $probe)) }}
{{- if not .Values.server.http.enabled }}
{{- fail (print "HTTP support must be enabled to enable " $probeName ": 'server.http.enabled'") }}
{{- end }}
{{- $probeName }}:
  {{- if or (hasKey $probe "tcpSocket") (and (not (hasKey $probe "tcpSocket")) (not (hasKey $probe "httpGet"))) }}
  tcpSocket:
    port: {{ .Values.server.http.port }}
  {{- else if hasKey $probe "httpGet" }}
  httpGet:
    port: {{ .Values.server.http.port }}
    {{- if or (empty $probe.httpGet) (not (hasKey $probe.httpGet "path")) }}
    path: /
    {{- else }}
    {{- toYaml (omit $probe.httpGet "port") | nindent 4 -}}
    {{ end }}
  {{- end }}
  {{- toYaml (omit (omit $probe "httpGet") "tcpSocket") | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Declares the Varnish Cache container
*/}}
{{- define "varnish-cache.serverContainer" -}}
{{- $cmdfileConfig := include "varnish-cache.cmdfileConfig" . }}
{{- $defaultVcl := osBase .Values.server.vclConfigPath }}
{{- $tp := kindOf .Values.server.extraArgs }}
{{- $varnishExtraArgs := list }}
{{- if eq $tp "string" }}
{{- $varnishExtraArgs = append $varnishExtraArgs .Values.server.extraArgs }}
{{- else }}
{{- $varnishExtraArgs = concat $varnishExtraArgs .Values.server.extraArgs }}
{{- end }}
{{- if not (eq $cmdfileConfig "") }}
{{- $varnishExtraArgs = concat $varnishExtraArgs (list "-I" .Values.server.cmdfileConfigPath) }}
{{- end }}
{{- range .Values.server.extraListens }}
{{- $extraArg := "" }}
{{- if .name }}
{{- $extraArg = print $extraArg .name "=" }}
{{- end }}
{{- if and .address .port }}
{{- $extraArg = print $extraArg .address ":" .port }}
{{- else if .port }}
{{- $extraArg = print $extraArg ":" .port }}
{{- else if .path }}
{{- $extraArg = print $extraArg .path }}
{{- if .user }}
{{- $extraArg = print $extraArg ",user=" .user }}
{{- end }}
{{- if .group }}
{{- $extraArg = print $extraArg ",group=" .group }}
{{- end }}
{{- if .mode }}
{{- $extraArg = print $extraArg ",mode=" .mode }}
{{- end }}
{{- else }}
{{ fail "Extra listens require either port or path: 'server.extraListens[].port' or 'server.extraListens[].path'" }}
{{- end }}
{{- if .proto }}
{{- $extraArg = print $extraArg "," .proto }}
{{- end }}
{{- $varnishExtraArgs = concat $varnishExtraArgs (list "-a" $extraArg) }}
{{- end }}
- name: {{ .Chart.Name }}
  {{- if not (and (empty .Values.global.securityContext) (empty .Values.server.securityContext)) }}
  securityContext:
    {{- if not (empty .Values.global.securityContext) }}
    {{- toYaml .Values.global.securityContext | nindent 4 }}
    {{- end }}
    {{- if not (empty .Values.server.securityContext) }}
    {{- toYaml .Values.server.securityContext | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- include "varnish-cache.image" (merge (dict "image" .Values.server.image) .) | nindent 2 }}
  ports:
    {{- if .Values.server.http.enabled }}
    - name: http
      containerPort: {{ .Values.server.http.port }}
      protocol: TCP
      {{- if and .Values.server.http.hostPort (not (empty .Values.server.http.hostPort)) }}
      hostPort: {{ .Values.server.http.hostPort }}
      {{- end }}
    {{- end }}
    {{- range .Values.server.extraListens }}
    {{- if not .name }}
    {{- fail "Name must be set in extraListens: 'server.extraListens[].name'" }}
    {{- end }}
    - name: extra-{{ .name }}
      containerPort: {{ .port }}
      protocol: TCP
      {{- if and .hostPort (not (empty .hostPort)) }}
      hostPort: {{ .hostPort }}
      {{- end }}
    {{- end }}
  {{- include "varnish-cache.varnishPodProbe" (merge (dict "probeName" "startupProbe") .) | nindent 2 }}
  {{- include "varnish-cache.varnishPodProbe" (merge (dict "probeName" "livenessProbe") .) | nindent 2 }}
  {{- include "varnish-cache.varnishPodProbe" (merge (dict "probeName" "readinessProbe") .) | nindent 2 }}
  {{- if and .Values.server.resources (not (empty .Values.server.resources)) }}
  resources: {{- toYaml .Values.server.resources | nindent 4 }}
  {{- end }}
  command:
    - /usr/sbin/varnishd
    - -F
    {{- if .Values.server.http.enabled }}
    - -a
    - http=$(VARNISH_HTTP_ADDRESS):{{ .Values.server.http.port }},HTTP
    {{- end }}
    {{- if not (eq (include "varnish-cache.vclConfig" .) "") }}
    - -f
    - {{ .Values.server.vclConfigPath }}
    {{- end }}
    {{- if .Values.server.admin.port }}
    - -T
    - {{ .Values.server.admin.address }}:{{ .Values.server.admin.port }}
    {{- end }}
    {{- if .Values.server.ttl }}
    - -t
    - {{ .Values.server.ttl | quote }}
    {{- end }}
    {{- if .Values.server.minThreads }}
    - -p
    - thread_pool_min={{ .Values.server.minThreads }}
    {{- end }}
    {{- if .Values.server.maxThreads }}
    - -p
    - thread_pool_max={{ .Values.server.maxThreads }}
    {{- end }}
    {{- if .Values.server.threadTimeout }}
    - -p
    - thread_pool_timeout={{ .Values.server.threadTimeout }}
    {{- end }}
    {{- if or (not (eq .Values.server.secret "")) (not (empty .Values.server.secretFrom)) }}
    - -S
    - /etc/varnish/secret
    {{- end }}
    {{- if (not (empty $varnishExtraArgs)) }}
    {{- range $v := $varnishExtraArgs }}
    - {{ $v | quote }}
    {{- end }}
    {{- end }}
  env:
    - name: VARNISH_HTTP_ADDRESS
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    {{- include "varnish-cache.toEnv" (merge (dict "envs" .Values.server.extraEnvs) .) | nindent 4 }}
  volumeMounts:
    - name: {{ .Release.Name }}-config
      mountPath: /etc/varnish
    {{- if and (not (empty .Values.server.secretFrom)) (hasKey .Values.server.secretFrom "name") (hasKey .Values.server.secretFrom "key") }}
    - name: {{ .Release.Name }}-config-secret
      mountPath: /etc/varnish/secret
      subPath: {{ .Values.server.secretFrom.key | quote }}
    {{- else if not (eq (include "varnish-cache.secretConfig" .) "") }}
    - name: {{ .Release.Name }}-config-secret
      mountPath: /etc/varnish/secret
      subPath: secret
    {{- end }}
    {{- if not (eq (include "varnish-cache.vclConfig" .) "") }}
    - name: {{ .Release.Name }}-config-vcl
      mountPath: {{ .Values.server.vclConfigPath | quote }}
      subPath: {{ $defaultVcl }}
    {{- end }}
    {{- $vclConfigs := omit .Values.server.vclConfigs $defaultVcl }}
    {{- if not (empty $vclConfigs) }}
    {{- range $k, $v := $vclConfigs }}
    - name: {{ $.Release.Name }}-config-vcl-{{ regexReplaceAll "\\W+" $k "-" }}
      mountPath: {{ list (dir $.Values.server.vclConfigPath) $k | join "/" | quote }}
      subPath: {{ $k | quote }}
    {{- end }}
    {{- end }}
    {{- if not (eq (include "varnish-cache.cmdfileConfig" .) "") }}
    - name: {{ .Release.Name }}-config-cmdfile
      mountPath: {{ .Values.server.cmdfileConfigPath | quote }}
      subPath: cmds.cli
    {{- end }}
    - name: {{ .Release.Name }}-varnish-vsm
      mountPath: /var/lib/varnish
    {{- if .Values.server.extraVolumeMounts }}
    {{- $tp := kindOf .Values.server.extraVolumeMounts }}
    {{- if eq $tp "string" }}
    {{- tpl .Values.server.extraVolumeMounts . | trim | nindent 4 }}
    {{- else }}
    {{- toYaml .Values.server.extraVolumeMounts | nindent 4 }}
    {{- end }}
    {{- end }}
  {{- if .Values.server.delayedHaltSeconds }}
  lifecycle:
    preStop:
      exec:
        command: ["/bin/sleep", {{ .Values.server.delayedHaltSeconds | quote }}]
  {{- end }}
{{- end }}

{{/*
Declares the Varnish NCSA container
*/}}
{{- define "varnish-cache.ncsaContainer" -}}
{{- if .Values.server.varnishncsa.enabled }}
- name: {{ .Chart.Name }}-ncsa
  {{- if not (and (empty .Values.global.securityContext) (empty .Values.server.varnishncsa.securityContext)) }}
  securityContext:
    {{- if not (empty .Values.global.securityContext) }}
    {{- toYaml .Values.global.securityContext | nindent 4 }}
    {{- end }}
    {{- if not (empty .Values.server.varnishncsa.securityContext) }}
    {{- toYaml .Values.server.varnishncsa.securityContext | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- include "varnish-cache.image" (merge (dict "base" .Values.server.image "image" .Values.server.varnishncsa.image) .) | nindent 2 }}
  {{- if and .Values.server.varnishncsa.resources (not (empty .Values.server.varnishncsa.resources)) }}
  resources: {{- toYaml .Values.server.varnishncsa.resources | nindent 4 }}
  {{- end }}
  command: ["varnishncsa"]
  {{- if and .Values.server.varnishncsa.extraArgs (not (empty .Values.server.varnishncsa.extraArgs)) }}
  args: {{- toYaml .Values.server.varnishncsa.extraArgs | nindent 4 }}
  {{- end }}
  {{- if and .Values.server.varnishncsa.startupProbe (not (empty .Values.server.varnishncsa.startupProbe)) }}
  startupProbe:
    exec:
      command:
        - /usr/bin/varnishncsa
        - -d
        - -t 3
    {{- toYaml .Values.server.varnishncsa.startupProbe | nindent 4 }}
  {{- end }}
  {{- if and .Values.server.varnishncsa.readinessProbe (not (empty .Values.server.varnishncsa.readinessProbe)) }}
  readinessProbe:
    exec:
      command:
        - /usr/bin/varnishncsa
        - -d
        - -t 3
    {{- toYaml .Values.server.varnishncsa.readinessProbe | nindent 4 }}
  {{- end }}
  {{- if and .Values.server.varnishncsa.livenessProbe (not (empty .Values.server.varnishncsa.livenessProbe)) }}
  livenessProbe:
    exec:
      command:
        - /usr/bin/varnishncsa
        - -d
        - -t 3
    {{- toYaml .Values.server.varnishncsa.livenessProbe | nindent 4 }}
  {{- end }}
  volumeMounts:
  - name: {{ .Release.Name }}-varnish-vsm
    mountPath: /var/lib/varnish
{{- end }}
{{- end }}

{{/*
Declares the Varnish deployment strategy
*/}}
{{- define "varnish-cache.strategy" -}}
{{- if .Values.server.strategy }}
{{- $tp := kindOf .Values.server.strategy }}
strategy:
{{- if eq $tp "string" }}
  {{- tpl .Values.server.strategy . | trim | nindent 2 }}
{{- else }}
  {{- toYaml .Values.server.strategy | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Declares the Varnish DaemonSet and StatefulSet updateStrategy
*/}}
{{- define "varnish-cache.updateStrategy" -}}
{{- if .Values.server.updateStrategy }}
{{- $tp := kindOf .Values.server.updateStrategy }}
updateStrategy:
{{- if eq $tp "string" }}
  {{- tpl .Values.server.updateStrategy . | trim | nindent 2 }}
{{- else }}
  {{- toYaml .Values.server.updateStrategy | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Declares the Varnish extra container
*/}}
{{- define "varnish-cache.extraContainers" -}}
{{- if .Values.server.extraContainers }}
{{- $tp := kindOf .Values.server.extraContainers }}
{{- if eq $tp "string" }}
  {{- tpl .Values.server.extraContainers . | trim | nindent 0 }}
{{- else }}
  {{- toYaml .Values.server.extraContainers | nindent 0 }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Declares the Varnish init containers
*/}}
{{- define "varnish-cache.initContainers" -}}
{{- if .Values.server.extraInitContainers }}
initContainers:
  {{- $tp := kindOf .Values.server.extraInitContainers }}
  {{- if eq $tp "string" }}
    {{- tpl .Values.server.extraInitContainers . | trim | nindent 2 }}
  {{- else }}
    {{- toYaml .Values.server.extraInitContainers | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}
