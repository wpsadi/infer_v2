import { Hono } from "hono";
import type { AppEnv } from "@/types/ context";

const app = new Hono<AppEnv>();

app.get( "/", ( c ) => c.text( "Hello from inference!" ) );
app.get( "/health", ( c ) => c.json( { status: "ok" } ) );
app.get( "no-idea", c => {
    console.log( "no-idea" )
    return c.json( { status: "ok" } )
} )

app.post( '/upload', async ( c ) => {
    const body = await c.req.parseBody( { all: true } )
    const value = body['file']

    const files = Array.isArray( value )
        ? value.filter( ( item ): item is File => item instanceof File )
        : value instanceof File
            ? [value]
            : []

    if ( files.length === 0 ) {
        return c.text( 'At least one file is required', 400 )
    }

    return c.json( {
        count: files.length,
        files: files.map( ( file ) => ( {
            name: file.name,
            size: file.size,
            type: file.type,
        } ) ),
    } )
} )

export default app;
