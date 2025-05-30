<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY a      "https://w3id.org/atomgraph/core#">
    <!ENTITY lacl   "https://w3id.org/atomgraph/linkeddatahub/admin/acl#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY prov   "http://www.w3.org/ns/prov#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ldh="&ldh;"
xmlns:ac="&ac;"
xmlns:a="&a;"
xmlns:lacl="&lacl;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:dh="&dh;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:template match="*[@rdf:about = '&acl;Authorization']" mode="ac:label">
        <xsl:apply-templates select="key('resources', 'authorization', document('../../../translations.rdf'))" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="acl:mode/@rdf:resource | acl:mode/@rdf:nodeID" mode="bs2:FormControl" priority="1">
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:variable name="this" select="../concat(namespace-uri(), local-name())" as="xs:string"/>
        <xsl:variable name="properties" select="../../*[concat(namespace-uri(), local-name()) = $this]" as="element()*"/>

        <xsl:variable name="modes" select="key('resources-by-subclass', '&acl;Access', document(ac:document-uri('&acl;')))" as="element()*"/>
        <select name="ou" id="{generate-id()}" multiple="multiple" size="{count($modes)}">
            <xsl:for-each select="$modes">
                <xsl:sort select="ac:label(.)" lang="{$ldt:lang}"/>
                <xsl:apply-templates select="." mode="xhtml:Option">
                    <xsl:with-param name="selected" select="@rdf:about = $properties/@rdf:resource"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </select>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="acl:mode[position() &gt; 1]" mode="bs2:FormControl" priority="2"/>

    <xsl:template match="*[rdf:type/@rdf:resource = '&lacl;AuthorizationRequest']" priority="1">
        <xsl:param name="method" select="'post'" as="xs:string"/>
        <xsl:param name="action" select="ldh:href($ldt:base, resolve-uri(ac:uuid() || '/', resolve-uri('acl/authorizations/', $ldt:base)), map{ '_method': 'PUT' })" as="xs:anyURI"/> <!-- create new authorization document -->
        <xsl:param name="id" select="concat('form-', generate-id())" as="xs:string?"/>
        <xsl:param name="class" select="'form-horizontal'" as="xs:string?"/>
        <xsl:param name="accept-charset" select="'UTF-8'" as="xs:string?"/>
        <xsl:param name="enctype" as="xs:string?"/> <!-- TO-DO: override with "multipart/form-data" for File instances -->

        <xsl:next-match/>
        
        <xsl:if test="lacl:requestMode/@rdf:resource = '&acl;Control'">
            <div class="alert">
                <p>
                    <strong>Warning!</strong> By allowing <code>Control</code> access mode you are effectively granting full control of the dataspace.
                </p>
            </div>
        </xsl:if>
        
        <!-- .form-horizontal is required so that client.xsl can match this form and intercept its onsubmit event -->
        <form method="{$method}" action="{$action}">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$accept-charset">
                <xsl:attribute name="accept-charset" select="$accept-charset"/>
            </xsl:if>
            <xsl:if test="$enctype">
                <xsl:attribute name="enctype" select="$enctype"/>
            </xsl:if>
            
            <xsl:comment>This form uses RDF/POST encoding: https://atomgraph.github.io/RDF-POST/</xsl:comment>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'rdf'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            
            <!-- acl:Authorization instance -->
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'sb'"/>
                <xsl:with-param name="value" select="'auth'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'pu'"/>
                <xsl:with-param name="value" select="'&rdf;type'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'ou'"/>
                <xsl:with-param name="value" select="'&acl;Authorization'"/> <!-- Authorization class URI -->
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'pu'"/>
                <xsl:with-param name="value" select="'&rdfs;label'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:variable name="label" select="string-join(lacl:requestMode/@rdf:resource/ac:label(key('resources', ., document(ac:document-uri('&acl;')))), ', ')" as="xs:string"/>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'ol'"/>
                <xsl:with-param name="value" select="'Allowed ' || $label || ' access'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'pu'"/>
                <xsl:with-param name="value" select="'&acl;agent'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'ou'"/>
                <xsl:with-param name="value" select="lacl:requestAgent/@rdf:resource"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:for-each select="lacl:requestAccessTo/@rdf:resource">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="value" select="'&acl;accessTo'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ou'"/>
                    <xsl:with-param name="value" select="."/>
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="lacl:requestAccessToClass/@rdf:resource">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="value" select="'&acl;accessToClass'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ou'"/>
                    <xsl:with-param name="value" select="."/>
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="lacl:requestMode/@rdf:resource">
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'pu'"/>
                    <xsl:with-param name="value" select="'&acl;mode'"/>
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:call-template>
                <xsl:call-template name="xhtml:Input">
                    <xsl:with-param name="name" select="'ou'"/>
                    <xsl:with-param name="value" select="."/>
                    <xsl:with-param name="type" select="'hidden'"/>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'pu'"/>
                <xsl:with-param name="value" select="'&prov;wasDerivedFrom'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'ou'"/>
                <xsl:with-param name="value" select="@rdf:about"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>

            <!-- dh:Item document -->
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'su'"/>
                <xsl:with-param name="value" select="''"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'pu'"/>
                <xsl:with-param name="value" select="'&rdf;type'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'ou'"/>
                <xsl:with-param name="value" select="'&dh;Item'"/> <!-- Item class URI -->
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'pu'"/>
                <xsl:with-param name="value" select="'&dct;title'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:variable name="label" select="string-join(lacl:requestMode/@rdf:resource/ac:label(key('resources', ., document(ac:document-uri('&acl;')))), ', ')" as="xs:string"/>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'ol'"/>
                <xsl:with-param name="value" select="'Allowed ' || $label || ' access'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'pu'"/>
                <xsl:with-param name="value" select="'&foaf;primaryTopic'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>
            <xsl:call-template name="xhtml:Input">
                <xsl:with-param name="name" select="'ob'"/>
                <xsl:with-param name="value" select="'auth'"/>
                <xsl:with-param name="type" select="'hidden'"/>
            </xsl:call-template>

            <div class="form-actions">
                <button type="submit" class="btn btn-primary">Allow</button>
            </div>
        </form>
    </xsl:template>
    
</xsl:stylesheet>