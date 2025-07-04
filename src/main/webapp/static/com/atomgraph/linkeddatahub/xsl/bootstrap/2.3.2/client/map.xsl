<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY gs     "http://www.opengis.net/ont/geosparql#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:geo="&geo;"
xmlns:ldt="&ldt;"
xmlns:gs="&gs;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>
    
    <!-- FUNCTIONS -->

    <!-- creates OpenLayers map object -->
    
    <xsl:function name="ldh:create-map">
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="lat" as="xs:float?"/>
        <xsl:param name="lng" as="xs:float?"/>
        <xsl:param name="zoom" as="xs:integer?"/>

        <xsl:variable name="tile-options" select="ldh:new-object()"/>
        <ixsl:set-property name="source" select="ldh:new('ol.source.OSM', [])" object="$tile-options"/>
        <xsl:variable name="tile" select="ldh:new('ol.layer.Tile', [ $tile-options ])"/>
        <xsl:variable name="layers" select="[ $tile ]" as="array(*)"/>

        <xsl:variable name="view-options" select="ldh:new-object()"/>
        <!--
        Saxon-JS issue: https://saxonica.plan.io/issues/5656#note-4 - call view.setCenter() instead
        <ixsl:set-property name="center" select="$center" object="$view-options"/>
        -->
        <xsl:if test="exists($zoom)">
            <ixsl:set-property name="zoom" select="$zoom" object="$view-options"/>
        </xsl:if>
        <xsl:variable name="view" select="ldh:new('ol.View', [ $view-options ])"/>
        
        <xsl:variable name="map-options" select="ldh:new-object()"/>
        <ixsl:set-property name="target" select="$canvas-id" object="$map-options"/>
        <ixsl:set-property name="layers" select="$layers" object="$map-options"/>
        <ixsl:set-property name="view" select="$view" object="$map-options"/>

        <xsl:variable name="map" select="ldh:new('ol.Map', [ $map-options ])"/>
        <xsl:if test="exists($lat) and exists($lng)">
            <xsl:variable name="lon-lat" select="[ $lng, $lat ]" as="array(*)"/>
            <xsl:variable name="center" select="ixsl:call(ixsl:get(ixsl:window(), 'ol.proj'), 'fromLonLat', [ $lon-lat ])"/>
            <xsl:sequence select="ixsl:call($view, 'setCenter', [ $center ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
        
        <xsl:variable name="js-function" select="ixsl:get(ixsl:window(), 'ixslTemplateListener')"/>
        <xsl:variable name="js-function" select="ixsl:call($js-function, 'bind', [ (), 'MapMarkerClick', $map ])"/> <!-- will invoke template onMapMarkerClick -->
        <xsl:sequence select="ixsl:call($map, 'on', [ 'click', $js-function ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:variable name="js-function" select="ixsl:get(ixsl:window(), 'ixslTemplateListener')"/>
        <xsl:variable name="js-function" select="ixsl:call($js-function, 'bind', [ (), 'MapMoveEnd', $map ])"/> <!-- will invoke template onMapMoveEnd -->
        <xsl:sequence select="ixsl:call($map, 'on', [ 'moveend', $js-function ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:variable name="js-statement" as="xs:string">
            <![CDATA[
                function (map, evt) {
                    if (!evt.dragging) {
                        var feature = map.forEachFeatureAtPixel(map.getEventPixel(evt.originalEvent), function(feature) {
                                return feature;
                            });
                        if (feature && feature.getId() && (feature.getId().startsWith('http://') || feature.getId().startsWith('https://'))) {
                            map.getTargetElement().style.cursor = 'pointer';
                        }
                        else {
                            map.getTargetElement().style.cursor = '';
                        }
                    }
                }
            ]]>
        </xsl:variable>
        <xsl:variable name="js-function" select="ixsl:eval(normalize-space($js-statement))"/> <!-- need normalize-space() due to Saxon-JS 2.4 bug: https://saxonica.plan.io/issues/5667 -->
        <xsl:variable name="js-function" select="ixsl:call($js-function, 'bind', [ (), $map ])"/>
        <xsl:sequence select="ixsl:call($map, 'on', [ 'pointermove', $js-function ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:sequence select="$map"/>
    </xsl:function>

    <!-- TEMPLATES -->

    <xsl:template match="rdf:Description" mode="ldh:GeoJSONProperties">
        <json:string key="name">
            <xsl:value-of select="ac:label(.)"/>
        </json:string>
        
        <xsl:if test="rdf:type/@rdf:resource">
            <json:array key="types">
                <xsl:for-each select="rdf:type/@rdf:resource">
                    <json:string>
                        <xsl:value-of select="."/>
                    </json:string>
                </xsl:for-each>
            </json:array>
        </xsl:if>
    </xsl:template>
    
    <!-- load geo resources with a given boundary -->
    
    <xsl:template name="ldh:LoadGeoResources">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" as="xs:string"/>
        <xsl:param name="block-uri" as="xs:anyURI"/>
        <xsl:param name="select-xml" as="document-node()"/>
        <xsl:param name="endpoint" as="xs:anyURI"/>
        <xsl:param name="base-uri" as="xs:anyURI"/>
        
        <!-- wrap SELECT into a DESCRIBE -->
        <xsl:variable name="query-xml" as="element()">
            <xsl:apply-templates select="$select-xml" mode="ldh:wrap-describe"/>
        </xsl:variable>
        <xsl:variable name="query-json-string" select="xml-to-json($query-xml)" as="xs:string"/>
        <xsl:variable name="query-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $query-json-string ])"/>
        <xsl:variable name="query-string" select="ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromQuery', [ $query-json ]), 'toString', [])" as="xs:string"/>
        <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path($base-uri), map{}, $results-uri)" as="xs:anyURI"/>
        <xsl:variable name="request" select="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }" as="map(*)"/>
        <xsl:variable name="context" as="map(*)" select="
          map{
            'request': $request,
            'container': $container,
            'container-id': $container-id,
            'block-uri': $block-uri
          }"/>
        <ixsl:promise select="ixsl:http-request($context('request')) =>
            ixsl:then(ldh:rethread-response($context, ?)) =>
            ixsl:then(ldh:handle-response#1) =>
            ixsl:then(ldh:geo-results-response#1)"
            on-failure="ldh:promise-failure#1"/>
    </xsl:template>
    
    <!-- create and render OpenLayers map -->
    
    <xsl:template name="ldh:DrawMap">
        <xsl:context-item as="document-node()" use="required"/>
        <xsl:param name="block-uri" as="xs:anyURI"/>
        <xsl:param name="canvas-id" as="xs:string"/>
        <xsl:param name="initial-load" select="not(ixsl:contains(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'map'))" as="xs:boolean"/>
        <xsl:param name="max-zoom" select="16" as="xs:integer"/>
        <xsl:param name="padding" select="(10, 10, 10, 10)" as="xs:integer*"/>
        <xsl:variable name="zoom" select="if (not($initial-load)) then xs:integer(ixsl:call(ixsl:call(ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`'), 'map'), 'getView', []), 'getZoom', [])) else 4" as="xs:integer"/>
        <xsl:variable name="map" select="ldh:create-map($canvas-id, 0, 0, $zoom)" as="item()"/>
        <ixsl:set-property name="map" select="$map" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $block-uri || '`')"/>

        <xsl:call-template name="ldh:AddMapLayers">
            <xsl:with-param name="map" select="$map"/>
        </xsl:call-template>
        
        <xsl:if test="$initial-load">
            <xsl:variable name="extent" select="ixsl:call(ixsl:get(ixsl:window(), 'ol.extent'), 'createEmpty', [])" as="xs:double*"/>
            <xsl:variable name="js-statement" as="xs:string">
                <![CDATA[
                    function (extent) {
                        this.getLayers().forEach(function(layer) {
                            if (layer instanceof ol.layer.Vector)
                                ol.extent.extend(extent, layer.getSource().getExtent());
                        });
                        
                        return extent;
                    }
                ]]>
            </xsl:variable>
            <xsl:variable name="js-function" select="ixsl:eval(normalize-space($js-statement))"/> <!-- need normalize-space() due to Saxon-JS 2.4 bug: https://saxonica.plan.io/issues/5667 -->
            <xsl:variable name="extent" select="ixsl:call($js-function, 'call', [ $map, $extent ])"/>
            
            <!-- only fit map view to $extent if it's not empty -->
            <xsl:if test="not(ixsl:call(ixsl:get(ixsl:window(), 'ol.extent'), 'isEmpty', [ $extent ]))">
                <xsl:variable name="fit-options" as="map(xs:string, item())">
                    <xsl:map>
                        <xsl:map-entry key="'maxZoom'" select="$max-zoom"/>
                        <xsl:map-entry key="'padding'" select="array{ $padding }"/>
                    </xsl:map>
                </xsl:variable>
                <xsl:variable name="fit-options-obj" select="ixsl:call(ixsl:window(), 'JSON.parse', [ $fit-options => serialize(map{ 'method': 'json' }) ])"/>

                <xsl:sequence select="ixsl:call(ixsl:call($map, 'getView', []), 'fit', [ $extent, $fit-options-obj ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- transforms geo resources in RDF/XML to GeoJSON and adds them to the map as a feature layer -->
    
    <xsl:template name="ldh:AddMapLayers">
        <xsl:context-item as="document-node()" use="required"/>
        <xsl:param name="map" as="item()"/>
        <xsl:param name="icons" select="(xs:anyURI('https://maps.google.com/mapfiles/ms/icons/blue-dot.png'), xs:anyURI('https://maps.google.com/mapfiles/ms/icons/red-dot.png'), xs:anyURI('https://maps.google.com/mapfiles/ms/icons/purple-dot.png'), xs:anyURI('https://maps.google.com/mapfiles/ms/icons/yellow-dot.png'), xs:anyURI('https://maps.google.com/mapfiles/ms/icons/green-dot.png'))" as="xs:anyURI*"/>
        <xsl:param name="icon-styles" as="item()*">
            <xsl:for-each select="$icons">
                <xsl:variable name="icon-options" select="ldh:new-object()"/>
                <!-- <ixsl:set-property name="anchor" select="" object="$icon-options"/> -->
                <ixsl:set-property name="anchorXUnits" select="'fraction'" object="$icon-options"/>
                <ixsl:set-property name="anchorYUnits" select="'pixels'" object="$icon-options"/>
                <!--<ixsl:set-property name="scale" select="0.2" object="$icon-options"/>-->
                <!-- icon has to have an initial src, otherwise the ol.style.Icon constructor will throw an assertion error -->
                <ixsl:set-property name="src" select="." object="$icon-options"/>
                <xsl:variable name="icon" select="ldh:new('ol.style.Icon', [ $icon-options ])"/>
                <xsl:sequence select="ixsl:call($icon, 'setAnchor', [ [0.5, 30] ])[current-date() lt xs:date('2000-01-01')]"/>

                <xsl:variable name="icon-style-options" select="ldh:new-object()"/>
                <ixsl:set-property name="image" select="$icon" object="$icon-style-options"/>
                <xsl:sequence select="ldh:new('ol.style.Style', [ $icon-style-options ])"/>
            </xsl:for-each>
        </xsl:param>
        <xsl:if test="count($icon-styles) = 0">
            <xsl:message>There should be at least one ol.style.Style instance in the $icon-styles sequence</xsl:message>
        </xsl:if>
        
        <!-- read geo:lat/geo:long features transformed using RDFXML2GeoJSON.xsl -->
        <xsl:variable name="geo-json-string" as="xs:string">
            <xsl:apply-templates select="." mode="ldh:GeoJSON"/>
        </xsl:variable>
        <xsl:variable name="geo-json" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'parse', [ $geo-json-string ])"/>
        <xsl:variable name="geo-json-options" select="ldh:new-object()"/>
        <ixsl:set-property name="featureProjection" select="'EPSG:3857'" object="$geo-json-options"/>
        <xsl:variable name="geo-json-features" select="array{ ixsl:call(ldh:new('ol.format.GeoJSON', []), 'readFeatures', [ $geo-json, $geo-json-options ]) }"/>

        <!-- read WKT features from gs:asWKT properties -->
        <xsl:variable name="wkt-options" select="ldh:new-object()"/>
        <ixsl:set-property name="dataProjection" select="'EPSG:4326'" object="$wkt-options"/>
        <ixsl:set-property name="featureProjection" select="'EPSG:3857'" object="$wkt-options"/>
        <!-- collect WKT features into an array -->
        <xsl:variable name="wkt-features" as="array(*)">
            <xsl:iterate select="/rdf:RDF/rdf:Description[gs:asWKT[@rdf:datatype = '&gs;wktLiteral']/text()]">
                <xsl:param name="features" select="array{}"/>

                <xsl:on-completion>
                    <xsl:sequence select="$features"/>
                </xsl:on-completion>

                <xsl:variable name="feature" select="ixsl:call(ldh:new('ol.format.WKT', []), 'readFeature', [ string(gs:asWKT[@rdf:datatype = '&gs;wktLiteral']/text()), $wkt-options ])"/>
                <xsl:sequence select="ixsl:call($feature, 'setId', [ string((@rdf:about, @rdf:nodeID)[1]) ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:sequence select="ixsl:call($feature, 'set', [ 'name', ac:label(.) ])[current-date() lt xs:date('2000-01-01')]"/>
                <xsl:sequence select="ixsl:call($feature, 'set', [ 'types', array{ rdf:type/@rdf:resource/string() } ])[current-date() lt xs:date('2000-01-01')]"/>

                <xsl:next-iteration>
                    <xsl:with-param name="features" select="array:append($features, $feature)"/>
                </xsl:next-iteration>
            </xsl:iterate>
        </xsl:variable>

        <xsl:variable name="text-options" select="ldh:new-object()"/>
        <ixsl:set-property name="font" select="'12px sans-serif'" object="$text-options"/>
        <ixsl:set-property name="offsetY" select="10" object="$text-options"/>
        <ixsl:set-property name="overflow" select="true()" object="$text-options"/>
        <xsl:variable name="text" select="ldh:new('ol.style.Text', [ $text-options ])"/>

        <xsl:variable name="label-style-options" select="ldh:new-object()"/>
        <ixsl:set-property name="text" select="$text" object="$label-style-options"/>
        <xsl:variable name="label-style" select="ldh:new('ol.style.Style', [ $label-style-options ])"/>

        <xsl:variable name="js-statement" as="xs:string">
            <![CDATA[
                function(labelStyle, iconStyles, typeIcons, feature) {
                    if (feature.get('name')) labelStyle.getText().setText(feature.get('name'));
                    
                    if (feature.getGeometry() instanceof ol.geom.Point) {
                        let iconStyle;
                        if (feature.get('types')) {
                            let type = feature.get('types')[0];

                            if (!typeIcons.has(type)) {
                                let iconIndex = typeIcons.size % iconStyles.length;
                                iconStyle = iconStyles[iconIndex];
                                typeIcons.set(type, iconStyle);
                            } else {
                                iconStyle = typeIcons.get(type);
                            }
                        }
                        else iconStyle = iconStyles[0];

                        return [ labelStyle, iconStyle ];
                    } else
                        return new ol.layer.Vector().getStyleFunction()().concat(labelStyle);
                }
            ]]>
        </xsl:variable>
        <xsl:variable name="js-function" select="ixsl:eval(normalize-space($js-statement))"/> <!-- need normalize-space() due to Saxon-JS 2.4 bug: https://saxonica.plan.io/issues/5667 -->
        <xsl:variable name="js-function" select="ixsl:call($js-function, 'bind', [ (), $label-style, $icon-styles, ldh:new('Map', []) ])"/>

        <xsl:variable name="source-options" select="ldh:new-object()"/>
        <!--<ixsl:set-property name="features" select="$geo-json-features" object="$source-options"/>-->
        <xsl:variable name="geo-json-source" select="ldh:new('ol.source.Vector', [ $source-options ])"/>
        <xsl:variable name="wkt-source" select="ldh:new('ol.source.Vector', [ $source-options ])"/>
        <!--<ixsl:set-property name="loader" select="$loader-function" object="$source-options"/>-->
        <xsl:sequence select="ixsl:call($geo-json-source, 'addFeatures', [ $geo-json-features ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="ixsl:call($wkt-source, 'addFeatures', [ $wkt-features ])[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:variable name="geo-json-layer-options" select="ldh:new-object()"/>
        <ixsl:set-property name="declutter" select="true()" object="$geo-json-layer-options"/>
        <ixsl:set-property name="source" select="$geo-json-source" object="$geo-json-layer-options"/>
        <ixsl:set-property name="style" select="$js-function" object="$geo-json-layer-options"/>
        <xsl:variable name="geo-json-layer" select="ldh:new('ol.layer.Vector', [ $geo-json-layer-options ])"/>

        <xsl:variable name="wkt-layer-options" select="ldh:new-object()"/>
        <!--<ixsl:set-property name="declutter" select="true()" object="$wkt-layer-options"/>-->
        <ixsl:set-property name="source" select="$wkt-source" object="$wkt-layer-options"/>
        <ixsl:set-property name="style" select="$js-function" object="$wkt-layer-options"/>
        <xsl:variable name="wkt-layer" select="ldh:new('ol.layer.Vector', [ $wkt-layer-options ])"/>

        <xsl:sequence select="ixsl:call($map, 'addLayer', [ $geo-json-layer ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:sequence select="ixsl:call($map, 'addLayer', [ $wkt-layer ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <!-- when container RDF/XML results load, render them -->
    <xsl:function name="ldh:geo-results-response" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:variable name="response" select="$context('response')" as="map(*)"/>
        <xsl:variable name="container" select="$context('container')" as="element()"/>
        <xsl:variable name="container-id" select="$context('container-id')" as="xs:string"/>
        <xsl:variable name="block-uri" select="$context('block-uri')" as="xs:anyURI"/>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        
        <xsl:for-each select="$response">
            <xsl:choose>
                <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                    <xsl:for-each select="?body">
                        <xsl:call-template name="ldh:DrawMap">
                            <xsl:with-param name="block-uri" select="$block-uri"/>
                            <xsl:with-param name="canvas-id" select="$container-id || '-map-canvas'"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- error response - could not load query results -->
                    <xsl:call-template name="render-container-error">
                        <xsl:with-param name="container" select="$container"/>
                        <xsl:with-param name="message" select="?message"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        
        <!-- loading is done - restore the default mouse cursor -->
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        
        <xsl:sequence select="$context"/>
    </xsl:function>

    <xsl:template match="." mode="ixsl:onMapMarkerClick">
        <xsl:param name="event" select="ixsl:event()"/>
        <xsl:param name="map" select="ixsl:get(ixsl:get($event, 'detail'), 'map')"/>
        <xsl:variable name="event" select="ixsl:get(ixsl:get($event, 'detail'), 'ol-event')"/> <!-- override the helper CustomEvent with the original OpenLayers event -->
        <xsl:variable name="js-statement" as="xs:string">
            <![CDATA[
                function (feat, layer) {
                    return feat;
                }
            ]]>
        </xsl:variable>
        <xsl:variable name="js-function" select="ixsl:eval(normalize-space($js-statement))"/> <!-- need normalize-space() due to Saxon-JS 2.4 bug: https://saxonica.plan.io/issues/5667 -->
        <xsl:variable name="feature" select="ixsl:call($map, 'forEachFeatureAtPixel', [ ixsl:get($event, 'pixel'), $js-function])" as="item()?"/>
        
        <xsl:if test="exists($feature)"> <!-- TO-DO: && feature.getGeometry() instanceof ol.geom.Point -->
            <xsl:variable name="id" select="xs:anyURI(ixsl:call($feature, 'getId', []))" as="xs:string"/>
            <xsl:if test="starts-with($id, 'http://') or starts-with($id, 'https://')"> <!-- InfoWindow not possible for blank nodes -->
                <xsl:variable name="uri" select="xs:anyURI($id)" as="xs:anyURI"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path($ldh:requestUri), map{}, ac:absolute-path($uri))" as="xs:anyURI"/>

                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                        <xsl:call-template name="onFeatureDescriptionLoad">
                            <xsl:with-param name="event" select="$event"/>
                            <xsl:with-param name="map" select="$map"/>
                            <xsl:with-param name="feature" select="$feature"/>
                            <xsl:with-param name="uri" select="$uri"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="onFeatureDescriptionLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="event"/>
        <xsl:param name="map"/>
        <xsl:param name="feature"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        
        <xsl:choose>
            <xsl:when test="?status = 200 and starts-with(?media-type, 'application/rdf+xml')">
                <xsl:for-each select="?body">
                    <xsl:variable name="info-window-options" select="ldh:new-object()"/>
                    <xsl:variable name="info-window-html" as="element()">
                        <xsl:apply-templates select="key('resources', $uri)">
                            <xsl:with-param name="show-edit-button" select="false()" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:variable name="coord" select="ixsl:get($event, 'coordinate')"/>
                    <xsl:variable name="container" select="ixsl:call(ixsl:page(), 'createElement', [ 'div' ])" as="element()"/>
                    <xsl:sequence select="ixsl:call(ixsl:call($map, 'getOverlayContainerStopEvent', []), 'appendChild', [ $container ])[current-date() lt xs:date('2000-01-01')]"/>
                    <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
                    <ixsl:set-attribute name="id" select="'id' || $uuid" object="$container"/>

                    <xsl:variable name="overlay-options" select="ldh:new-object()"/>
                    <ixsl:set-property name="element" select="$container" object="$overlay-options"/>
                    <ixsl:set-property name="autoPan" select="true()" object="$overlay-options"/>
                    <ixsl:set-property name="positioning" select="'bottom-center'" object="$overlay-options"/>
                    <!--<ixsl:set-property name="className" select="'ol-overlay-container ol-selectable'" object="$overlay-options"/>-->
                    <!--<ixsl:set-property name="autoPanAnimation" select="" object="$overlay-options"/>-->
                    <xsl:variable name="overlay" select="ldh:new('ol.Overlay', [ $overlay-options ])"/>
                    <xsl:sequence select="ixsl:call($overlay, 'setPosition', [ $coord ])[current-date() lt xs:date('2000-01-01')]"/>

                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <div class="modal-header">
                                <button type="button" class="close">&#215;</button>
                            </div>
                            
                            <div class="modal-body">
                                <xsl:sequence select="$info-window-html"/>
                            </div>
                        </xsl:result-document>
                    </xsl:for-each>
                
                    <xsl:sequence select="ixsl:call($map, 'addOverlay', [ $overlay ])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ ?message ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
    </xsl:template>
    
    <!-- close popup overlay (info window) -->
    
    <xsl:template match="div[contains-token(@class, 'ol-overlay-container')]//div[contains-token(@class, 'modal-header')]/button[contains-token(@class, 'close')]" mode="ixsl:onclick">
        <xsl:variable name="content-uri" select="ancestor::div[@about][1]/@about" as="xs:anyURI"/>
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'ol-overlay-container')]/div" as="element()"/>
        <xsl:variable name="map" select="ixsl:get(ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), '`' || $content-uri || '`'), 'map')"/>
        <xsl:variable name="overlay" select="ixsl:call(ixsl:call($map, 'getOverlays', []), 'getArray', [])[ ixsl:call(., 'getElement', []) is $container ]"/>
        <xsl:sequence select="ixsl:call($map, 'removeOverlay', [ $overlay ])[current-date() lt xs:date('2000-01-01')]"/> <!-- remove overlay from map -->
    </xsl:template>
    
</xsl:stylesheet>
