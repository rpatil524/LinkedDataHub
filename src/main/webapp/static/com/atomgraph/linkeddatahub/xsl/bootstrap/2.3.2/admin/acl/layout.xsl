<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:import href="imports/acl.xsl"/>
    <xsl:import href="imports/cert.xsl"/>

    <!-- TO-DO: refactor into component templates -->
    <xsl:template match="rdf:RDF" mode="bs2:NavBarNavList">
        <xsl:if test="$foaf:Agent//@rdf:about">
            <ul class="nav pull-right">
<!--                <li>
                    <xsl:if test="$ac:mode = '&ac;QueryEditorMode'">
                        <xsl:attribute name="class" select="'active'"/>
                    </xsl:if>

                    <a href="{ac:build-uri((), map{ 'mode': '&ac;QueryEditorMode' })}" class="query-editor">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'sparql-editor', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </a>
                </li>-->

                <xsl:variable name="notification-query" as="xs:string">
                    <![CDATA[
PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX  dct:  <http://purl.org/dc/terms/>
PREFIX  prov: <http://www.w3.org/ns/prov#>
PREFIX  foaf: <http://xmlns.com/foaf/0.1/>
PREFIX  sioc: <http://rdfs.org/sioc/ns#>

CONSTRUCT 
{ 
    ?authRequest a $type .
    ?authRequest rdfs:label ?label .
    ?authRequest dct:created ?created .
}
WHERE
{ GRAPH ?authRequestGraph
  { ?authRequest  a                 $type ;
              rdfs:label            ?label .
    ?authRequestItem
              foaf:primaryTopic  ?authRequest ;
              sioc:has_container    $container
    FILTER NOT EXISTS { GRAPH ?authGraph
                          { ?auth  prov:wasDerivedFrom  ?authRequest }
                      }
    OPTIONAL
      { ?authRequest  dct:created  ?created }
  }
}
                    ]]>
                </xsl:variable>
                <xsl:variable name="notification-query" select="replace($notification-query, '$type', '&lt;&lacl;AuthorizationRequest&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="notification-query" select="replace($notification-query, '$container', '&lt;' || resolve-uri('acl/authorization-requests/', $ldt:base) || '&gt;', 'q')" as="xs:string"/>

                <xsl:if test="doc-available(ac:build-uri(resolve-uri('sparql', $ldt:base), map{ 'query': $notification-query }))">
                    <xsl:variable name="notifications" select="document(ac:build-uri(resolve-uri('sparql', $ldt:base), map{ 'query': $notification-query }))" as="document-node()"/>

                    <xsl:if test="$notifications/rdf:RDF/*[@rdf:about]">
                        <li>
                            <div class="btn-group">
                                <button title="{ac:label(key('resources', 'notifications', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri))))}">
                                    <xsl:apply-templates select="key('resources', 'notifications', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ldh:logo">
                                        <xsl:with-param name="class" select="'btn btn-primary dropdown-toggle'"/>
                                    </xsl:apply-templates>
                                </button>
                                <ul class="dropdown-menu pull-right">
                                    <xsl:for-each select="$notifications/rdf:RDF/*[@rdf:about]">
                                        <xsl:sort select="dct:created[1]/xs:dateTime(.)" order="descending"/>

                                        <xsl:apply-templates select="." mode="xhtml:ListItem"/>
                                    </xsl:for-each>
                                </ul>
                            </div>
                        </li>
                    </xsl:if>
                </xsl:if>

                <li>
                    <div class="btn-group">
                        <button type="button" title="{ac:label($foaf:Agent//*[@rdf:about][1])}">
                            <xsl:apply-templates select="key('resources', '&foaf;Agent', document(ac:document-uri('&foaf;')))" mode="ldh:logo">
                                <xsl:with-param name="class" select="'btn dropdown-toggle'"/>
                            </xsl:apply-templates>
                        </button>
                        <ul class="dropdown-menu pull-right">
                            <li>
                                <xsl:for-each select="key('resources-by-type', '&foaf;Agent', $foaf:Agent)">
                                    <xsl:apply-templates select="@rdf:about" mode="xhtml:Anchor"/>
                                </xsl:for-each>
                            </li>
                        </ul>
                    </div>
                </li>
            </ul>
        </xsl:if>

        <xsl:apply-templates select="." mode="bs2:SignUp"/>
    </xsl:template>
    
</xsl:stylesheet>