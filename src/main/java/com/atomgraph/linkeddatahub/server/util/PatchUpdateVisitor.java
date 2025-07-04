/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

package com.atomgraph.linkeddatahub.server.util;

import org.apache.jena.sparql.core.Quad;
import org.apache.jena.sparql.modify.request.UpdateModify;
import org.apache.jena.sparql.modify.request.UpdateVisitorBase;

/**
 * Visitor for SPARQL PATCH updates to detect named graph usage.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class PatchUpdateVisitor extends UpdateVisitorBase
{

    private boolean containsNamedGraph = false;

    @Override
    public void visit(UpdateModify update)
    {
        update.getDeleteAcc().getQuads().forEach(quad ->
        {
            if (!quad.getGraph().equals(Quad.defaultGraphNodeGenerated)) containsNamedGraph = true;
        });
        update.getInsertAcc().getQuads().forEach(quad ->
        {
            if (!quad.getGraph().equals(Quad.defaultGraphNodeGenerated)) containsNamedGraph = true;
        });
    }

    /**
     * Returns true if the SPARQL update contains the <code>GRAPH</code> keyword in the <code>INSERT</code>/<code>DELETE</code> templates.
     * @return true if there is a named graph pattern
     */
    public boolean containsNamedGraph()
    {
        return containsNamedGraph;
    }
    
}
