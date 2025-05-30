/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.server.exception;

import jakarta.ws.rs.ClientErrorException;
import jakarta.ws.rs.core.Response;

/**
 * Exception thrown when the request body is larger than the configured maximum limit.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RequestContentTooLargeException extends ClientErrorException
{

    /**
     * Constructs exception.
     * 
     * @param maxContentLength maximum content length in bytes
     * @param contentLength actual content length in bytes
     */
    public RequestContentTooLargeException(long maxContentLength, long contentLength) // TO-DO: use sizes to generate a message?
    {
        super(Response.Status.REQUEST_ENTITY_TOO_LARGE);
    }
    
}
