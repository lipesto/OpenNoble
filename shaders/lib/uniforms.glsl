//MATRICES
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

//SAMPLERS
uniform  sampler2D noisetex;

uniform  sampler2D depthtex0;
uniform  sampler2D depthtex1;
uniform  sampler2D depthtex2;

uniform  sampler2D colortex0;
uniform  sampler2D colortex1;
uniform usampler2D colortex2;
uniform  sampler2D colortex3;

uniform  sampler2D colortex15;

//CUSTOM IMAGES
uniform sampler2D luts_transmittance;
uniform sampler2D luts_multiscattering;
uniform sampler2D luts_view;



uniform vec2 resolution;
uniform vec2 resolutionInv;
uniform vec3 cameraPositionFract;
uniform vec3 sunDir;
