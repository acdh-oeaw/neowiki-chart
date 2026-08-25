{{- define "neowiki.fullname" -}}
{{- default .Chart.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "neowiki.mediawiki.name" -}}
{{ include "neowiki.fullname" . }}-mediawiki
{{- end -}}

{{- define "neowiki.mediawiki.validateSecretToken" -}}
{{- $v := .Values.mediawiki.secretToken -}}
{{- if and $v (ge (len $v) 64) -}}
{{- $v -}}
{{- end -}}
{{- end -}}

{{- define "neowiki.mediawiki.validateAdminPassword" -}}
{{- $v := .Values.mediawiki.adminPassword -}}
{{- if and $v (ge (len $v) 10) -}}
{{- $v -}}
{{- end -}}
{{- end -}}

{{- define "neowiki.qlever.name" -}}
{{ include "neowiki.fullname" . }}-qlever
{{- end -}}

{{- define "neowiki.oxigraph.name" -}}
{{ include "neowiki.fullname" . }}-oxigraph
{{- end -}}

{{- define "neowiki.mariadb.host" -}}
{{- if .Values.externalDatabase.enabled -}}
{{ .Values.externalDatabase.host }}
{{- else -}}
{{ printf "%s-mariadb" (include "neowiki.fullname" .) }}
{{- end -}}
{{- end -}}

{{- define "neowiki.mariadb.name" -}}
{{- printf "%s-mariadb" (include "neowiki.fullname" .) -}}
{{- end -}}

{{- define "neowiki.mariadb.secret.name" -}}
{{- printf "%s-mariadb-auth" (include "neowiki.fullname" .) -}}
{{- end -}}

{{- define "neowiki.mariadb.database.name" -}}
{{- printf "%s-mariadb-database" (include "neowiki.fullname" .) -}}
{{- end -}}

{{- define "neowiki.mariadb.user.name" -}}
{{- printf "%s-mariadb-user" (include "neowiki.fullname" .) -}}
{{- end -}}

{{- define "neowiki.neo4j.urlExternal" -}}
{{- if .Values.externalNeo4j.enabled -}}
{{ .Values.externalNeo4j.httpUrl }}
{{- else -}}
{{ printf "http://%s-neo4j-lb-neo4j:7474" (include "neowiki.fullname" .) }}
{{- end -}}
{{- end -}}

{{- define "neowiki.neo4j.readAuthSecret.name" -}}
{{- printf "%s-read-auth" .Values.neo4j.neo4j.name -}}
{{- end -}}

{{- define "neowiki.qlever.url" -}}
{{ printf "http://%s:%d" (include "neowiki.qlever.name" .) (int .Values.qlever.service.port) }}
{{- end -}}

{{- define "neowiki.oxigraph.updateUrl" -}}
{{ printf "http://%s:%d/update" (include "neowiki.oxigraph.name" .) (int .Values.oxigraph.service.port) }}
{{- end -}}

{{- define "neowiki.oxigraph.queryUrl" -}}
{{ printf "http://%s:%d/query" (include "neowiki.oxigraph.name" .) (int .Values.oxigraph.service.port) }}
{{- end -}}