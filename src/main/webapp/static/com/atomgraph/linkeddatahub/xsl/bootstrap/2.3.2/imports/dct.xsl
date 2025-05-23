<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY adm    "https://w3id.org/atomgraph/linkeddatahub/admin#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY dct    "http://purl.org/dc/terms/">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:ldt="&ldt;"
xmlns:foaf="&foaf;"
xmlns:dct="&dct;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
exclude-result-prefixes="#all">

    <xsl:preserve-space elements="dct:description"/>
    
    <xsl:template match="dct:description/text()" mode="bs2:FormControl">
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        <xsl:param name="rows" select="10" as="xs:integer"/>
        
        <textarea name="ol" id="{generate-id()}" rows="{$rows}">
            <xsl:value-of select="."/>
        </textarea>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="dct:format/@rdf:nodeID" mode="bs2:FormControl">
        <xsl:param name="id" select="generate-id()" as="xs:string"/>
        <xsl:param name="class" as="xs:string?"/>
        <xsl:param name="disabled" select="false()" as="xs:boolean"/>
        <xsl:param name="type-label" select="true()" as="xs:boolean"/>
        
        <!-- the form will submit a literal value but the SkolemizingModelProvider will convert it to a URI resource -->
        <select name="ol">
            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$class">
                <xsl:attribute name="class" select="$class"/>
            </xsl:if>
            <xsl:if test="$disabled">
                <xsl:attribute name="disabled" select="'disabled'"/>
            </xsl:if>
            
            <option value="">[browser-defined]</option>
            <optgroup label="RDF triples">
                <option value="text/turtle">
                    <xsl:if test="ends-with(., 'text/turtle')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>
                    
                    <xsl:text>Turtle (.ttl)</xsl:text>
                </option>
                <option value="application/n-triples">
                    <xsl:if test="ends-with(., 'application/n-triples')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>
                    
                    <xsl:text>N-Triples (.nt)</xsl:text>
                </option>
                <option value="application/rdf+xml">
                    <xsl:if test="ends-with(., 'application/rdf+xml')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:text>RDF/XML (.rdf)</xsl:text>
                </option>
            </optgroup>
            <optgroup label="RDF quads">
                <option value="text/trig">
                    <xsl:if test="ends-with(., 'text/trig')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:text>TriG (.trig)</xsl:text>
                </option>
                <option value="application/n-quads">
                    <xsl:if test="ends-with(., 'application/n-quads')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:text>N-Quads (.nq)</xsl:text>
                </option>
            </optgroup>
            <optgroup label="Other">
                <option value="text/csv">
                    <xsl:if test="ends-with(., 'text/csv')">
                        <xsl:attribute name="selected" select="'selected'"/>
                    </xsl:if>

                    <xsl:text>CSV (.csv)</xsl:text>
                </option>
            </optgroup>
        </select>

        <xsl:if test="$type-label">
            <xsl:apply-templates select="." mode="bs2:FormControlTypeLabel"/>
        </xsl:if>
    </xsl:template>
     
</xsl:stylesheet>