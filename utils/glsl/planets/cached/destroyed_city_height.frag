
uniform float tex_scale  = 1.0;
uniform float ring_scale = 2.0;     // Amount of rings.
uniform float cut_off    = 0.2;
uniform int subdivisions = 80;

uniform float u_time;
uniform vec2 dimensions;
uniform int u_seed = 0;

vec3 hash( vec3 x )
{
   x = vec3( dot(x,vec3(127.1,311.7, 74.7)),
             dot(x,vec3(269.5,183.3,246.1)),
             dot(x,vec3(113.5,271.9,124.6)));
   return fract(sin(x)*43758.5453123);
}

/* 3D Voronoi- Inigo Qquilez (MIT) */
float voronoi( vec3 p )
{
   vec3 b, r, g = floor(p);
   p = fract(p);
   float d = 1.0;
   for(int j = -1; j <= 1; j++) {
      for(int i = -1; i <= 1; i++) {
         b = vec3(i, j, -1);
         r = b - p + hash(g+b);
         d = min(d, dot(r,r));
         b.z = 0.0;
         r = b - p + hash(g+b);
         d = min(d, dot(r,r));
         b.z = 1.0;
         r = b - p + hash(g+b);
         d = min(d, dot(r,r));
      }
   }
   return d;
}

/* Fractal brownian motion with voronoi! */
float voronoi_fbm( in vec3 p )
{
   float t = 0.0;
   float amp = 1.0;
   for (int i=0; i<5; i++) {
      t    += voronoi( p ) * amp;
      p    *= 2.0;
      amp  *= 0.5;
   }
   return t / 2.0;
}

float voronoi_rigded( in vec3 p )
{
   float t = 0.0;
   float amp = 1.0;
   for (int i=0; i<6; i++) {
      float noise = voronoi( p );
      t    += (1.0 - 2.0*noise) * amp;
      p    *= 2.0;
      amp  *= 0.75 - 0.25*noise;
   }
   return t / 2.0;
}

/* Compute coordinates on a sphere with radius 1. */
vec3 sphere_coords( vec2 uv )
{
   vec3 pos = vec3(sin(uv.x)*cos(uv.y), cos(uv.x)*cos(uv.y), sin(uv.y));
   return pos;
}

/* Compute height map. */
float heigth( vec3 pos )
{

   float h = voronoi( 3.0*tex_scale*pos + vec3(0,0,u_seed) );
   h = 2.0*voronoi_fbm( 5.0*ring_scale*vec3(h) ) - 0.25;
   h = 1.0 - clamp((h-cut_off)/(1.0-cut_off), 0.0, 1.0);
   h -= 1.5*max(voronoi_rigded( 3.0*pos - 0.5*vec3(u_seed) ) - 0.5, 0.0);
   return clamp(h, 0.0, 1.0);
}

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
   vec4 color_out = vec4(0.0);
   // Scaled UV coordinates.
   vec2 uv = 2.0*(screen_coords / dimensions - 0.5);
   // Sphere coordinates.
   vec3 pos = sphere_coords( M_PI * uv*vec2(1.0,0.5) );
   // Render the height map.
   float h = heigth( pos );
   h -= 0.5*clamp(2.0*h - 1.0, 0.0, 1.0)*max( max( abs(1.0 - 2.0*fract(2.0*float(subdivisions)*uv.x)) - 0.8, abs(1.0 - 2.0*fract(float(subdivisions)*uv.y)) - 0.8), 0.0 );

   color_out = vec4(vec3(h),1.0);

   return color_out;
}
